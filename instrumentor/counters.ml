open Cil
open Pretty
open Printf
open SchemeName


class manager name file =
  let counters = FindGlobal.find (name.prefix ^ "Counters") file in
  let counterField = match counters.vtype with
  | TArray (TComp ({cstruct = true} as compinfo, _), _, _) ->
      getCompField compinfo "count"
  | other ->
      ignore (bug "unexpected counters type %a\n" d_type other);
      failwith "internal error"
  in

  object (self)
    val mutable nextId = 0
    val siteInfos = new QueueClass.container
    val stamper = Timestamp.set file

    method private bump = Threads.bump file

    method addSite func selector (description : doc) location =
      let site = (Var counters, Index (integer nextId, NoOffset)) in
      nextId <- nextId + 1;
      let stamp = stamper site location in
      let counter = addOffsetLval (Field (counterField, selector)) site in
      let bump = self#bump counter location in
      let result = mkStmt (IsolateInstructions.isolate (bump :: stamp)) in
      Sites.registry#add func (Site.build result);
      siteInfos#push (func, location, description, result);
      result

    method patch =
      mapGlobals file
	begin
	  function
	    | GVar ({vtype = TArray (elementType, _, attributes)} as varinfo, initinfo, location)
	      when varinfo == counters
	      ->
		GVar ({varinfo with vtype = TArray (elementType,
						    Some (integer nextId),
						    attributes)},
		      initinfo, location)

	    | GFun ({svar = {vname = "samplerReporter"}; sbody = sbody}, _) as global
	      when nextId > 0 ->
		let schemeReporter = FindFunction.find (name.prefix ^ "Reporter") file in
		let call = Call (None, Lval (var schemeReporter), [], locUnknown) in
		sbody.bstmts <- mkStmtOneInstr call :: sbody.bstmts;
		global

	    | other ->
		other
	end

    method saveSiteInfo digest channel =
      fprintf channel "<sites unit=\"%s\" scheme=\"%s\">\n"
	(Digest.to_hex (Lazy.force digest)) name.flag;

      siteInfos#iter
	(fun (func, location, description, statement) ->
	  let description = Pretty.sprint max_int description in
	  fprintf channel "%s\t%d\t%s\t%d\t%s\n"
	    location.file location.line
	    func.svar.vname
	    statement.sid
	    description);

      output_string channel "</sites>\n"
  end
