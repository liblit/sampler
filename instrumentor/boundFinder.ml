open Cil
open Interesting


type direction = Min | Max


let updateBound best example direction location =
  let example = mkCast ~e:example ~newt:best.vtype in
  let best = var best in
  let op = match direction with
  | Min -> Lt
  | Max -> Gt
  in
  If (BinOp (op, example, Lval best, intType),
      mkBlock [mkStmtOneInstr (Set (best, example, location))],
      mkBlock [],
      location)


let makeGlobals =
  let nextId = ref 0 in
  fun typ ->
    let typ = match typ with
    | TEnum _ -> intType
    | _ -> typ
    in
    let prefix = "samplerBounds_" ^ (string_of_int !nextId) in
    incr nextId;
    let makeGlobal suffix =
      let result = makeGlobalVar (prefix ^ suffix) typ in
      result.vstorage <- Static;
      result
    in
    (makeGlobal "_min", makeGlobal "_max")


let extremesUnsigned typ =
  mkCast ~e:zero ~newt:typ,
  mkCast ~e:mone ~newt:typ


let extremesSigned bits typ =
  let shift initial =
    mkCast ~e:(kinteger64 ILongLong (Int64.shift_right initial (64 - bits))) ~newt:typ
  in
  shift Int64.min_int,
  shift Int64.max_int


let extremes typ =
  let builder = match typ with
  | TInt (ikind, _) ->
      if isSigned ikind then
	extremesSigned (bitsSizeOf typ)
      else
	extremesUnsigned
  | TEnum _ ->
      extremesSigned (bitsSizeOf intType)
  | TPtr _ ->
      extremesUnsigned
  | other ->
      ignore (bug "don't know extreme values of type %a\n" d_type other);
      failwith "internal error"
  in
  builder typ


class visitor global func =
  object (self)
    inherit SiteFinder.visitor

    val mutable globals = [global]
    method globals = globals

    method! vstmt stmt =
      let build replacement left location (host, offset) =
	let leftType = unrollType (typeOfLval left) in
	let newLeft = var (Locals.makeTempVar func leftType) in
	let min, max = makeGlobals leftType in
	let maxInit, minInit = extremes leftType in
	globals <-
	  GVar (min, {init = Some (SingleInit minInit)}, location) ::
	  GVar (max, {init = Some (SingleInit maxInit)}, location) ::
	  globals;
	let siteInfo = new BoundSiteInfo.c func location left host offset in
	let implementation = siteInfo#implementation in
	implementation.skind <- Block (mkBlock [mkStmt (updateBound min (Lval newLeft) Min location);
						mkStmt (updateBound max (Lval newLeft) Max location)]);
	Sites.registry#add func (Site.build implementation);
	BoundManager.register (min, max) siteInfo;
	Block (mkBlock [mkStmtOneInstr (replacement newLeft);
			implementation;
			mkStmtOneInstr (Set (left, Lval newLeft, location))])
      in

      let isInterestingLval = isInterestingLval isDiscreteType in

      match IsolateInstructions.isolated stmt with
      | Some (Set (left, expr, location))
	when self#includedStatement stmt ->
	  begin
	    match isInterestingLval left with
	    | None -> ()
	    | Some info ->
		let replacement = (fun temp -> Set (temp, expr, location)) in
		stmt.skind <- build replacement left location info;
	  end;
	  SkipChildren

      | Some (Call (Some left, callee, args, location))
	when self#includedStatement stmt ->
	  begin
	    match isInterestingLval left with
	    | None -> ()
	    | Some info ->
		let replacement = (fun temp -> Call (Some temp, callee, args, location)) in
		stmt.skind <- build replacement left location info;
	  end;
	  SkipChildren

      | _ ->
	  DoChildren
  end
