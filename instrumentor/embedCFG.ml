open Cil


class visitor =
  object (self)
    inherit FunctionBodyVisitor.visitor
    inherit BufferClass.c 16

    initializer
      self#addString "*0.0\n";

    val expectedSid = ref 0

    method private addLocation location =
      self#addString location.file;
      self#addChar '\t';
      self#addString (string_of_int location.line);
      self#addChar '\n'

    method postNewline thing =
      self#addChar '\n';
      thing

    method vglob = function
      | GFun (fundec, location) as global ->
	  self#addChar (if fundec.svar.vstorage == Static then '-' else '+');
	  self#addChar '\t';
	  self#addString fundec.svar.vname;
	  self#addChar '\t';
	  self#addLocation location;

	  IsolateInstructions.visit fundec;
	  Cfg.build fundec;
	  expectedSid := 0;

	  ChangeDoChildrenPost ([global], self#postNewline)

      | _ ->
	  SkipChildren

    method vstmt statement =
      assert (statement.sid == !expectedSid);
      incr expectedSid;

      (* statement location *)
      self#addLocation (get_stmtLoc statement.skind);

      (* successors list *)
      let addSucc {sid = succId} =
	self#addString (string_of_int succId);
	self#addChar '\t'
      in
      List.iter addSucc statement.succs;
      self#addChar '\n';

      (* callees list *)
      begin
	match statement.skind with
	| Instr [Call (_, Lval callee, _, _)] ->
	    begin
	      match Dynamic.resolve callee with
	      | Dynamic.Unknown ->
		  self#addString "???"
	      | Dynamic.Known callees ->
		  let addCallee {vname = vname} =
		    self#addString vname;
		    self#addChar '\t'
		  in
		  List.iter addCallee callees
	    end

	| Instr [Call (_, callee, _, _) as call] ->
	    ignore (bug "unexpected non-lval callee: %a" d_exp callee);
	    failwith "internal error"

	| _ ->
	    ()
      end;
      self#addChar '\n';

      DoChildren
  end


let visit file =
  Dynamic.analyze file;
  let visitor = new visitor in
  visitCilFileSameGlobals (visitor :> cilVisitor) file;
  visitor#addChar '\n';
  let contents = visitor#contents in

  let init = SingleInit (mkString contents) in
  let varinfo = makeGlobalVar "samplerCFG" (TArray (TInt (IChar, [Attr ("const", [])]), None, [])) in
  varinfo.vstorage <- Static;
  varinfo.vattr <- [Attr("section", [AStr ".debug_sampler_cfg"]); Attr("unused", [])];
  let global = GVar (varinfo, {init = Some init}, locUnknown) in

  file.globals <- global :: file.globals
