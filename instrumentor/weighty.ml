open Cil
open FuncInfo
open Str


let assumeWeightlessExterns =
  Options.registerBoolean
    ~flag:"assume-weightless-externs"
    ~desc:"assume that functions defined elsewhere have no sample sites"
    ~ident:"AssumeWeightlessExterns"
    ~default:false

let assumeWeightlessLibraries =
  Options.registerBoolean
    ~flag:"assume-weightless-libraries"
    ~desc:"assume that functions defined in libraries have no sample sites"
    ~ident:"AssumeWeightlessLibraries"
    ~default:true

let debugWeighty =
  Options.registerBoolean
    ~flag:"debug-weighty"
    ~desc:"print extra debugging information during weighty function analysis"
    ~ident:""
    ~default:false


(**********************************************************************)


let hasDefinition file =
  let defined = new VarinfoSet.container in
  let iterator = function
    | GFun (func, _) ->
	defined#add func.svar
    | _ -> ()
  in
  iterGlobals file iterator;
  defined#mem


let hasPragmaWeightless file =
  let assumed = new StringSet.container in
  let iterator = function
    | GPragma (Attr ("sampler_assume_weightless", [AStr (funcname)]), location) ->
	assumed#add funcname;
	if !debugWeighty then
	  ignore (Pretty.eprintf "%a: function %s is assumed weightless by pragma@!" d_loc location funcname)
    | _ -> ()
  in
  iterGlobals file iterator;
  fun callee -> assumed#mem callee.vname


let isWeightyLibrary =
  let pattern = regexp "^(bsearch|qsort)$|setjmp|longjmp" in
  fun varinfo -> string_match pattern varinfo.vname 0


let isBuiltin =
  let pattern = regexp "^__builtin_" in
  fun varinfo -> string_match pattern varinfo.vname 0


(**********************************************************************)


let isWeightyVarinfo hasDefinition hasPragmaWeightless weighty callee =
  if weighty#mem callee then
    true
  else if hasDefinition callee then
    false
  else if hasPragmaWeightless callee then
    false
  else if isWeightyLibrary callee then
    true
  else if !assumeWeightlessLibraries && Libraries.functions#mem callee.vname then
    false
  else if isBuiltin callee then
    false
  else if !assumeWeightlessExterns then
    false
  else
    true


let isWeightyLval hasDefinition hasPragmaWeightless weighty lval =
  match Dynamic.resolve lval with
  | Dynamic.Unknown ->
      true
  | Dynamic.Known possibilities ->
    List.exists (isWeightyVarinfo hasDefinition hasPragmaWeightless weighty) possibilities


(**********************************************************************)


exception ContainsWeightyCall of location * lval


class visitor hasDefinition hasPragmaWeightless weighty =
  object
    inherit FunctionBodyVisitor.visitor

    method vfunc func =
      if weighty#mem func.svar then
	SkipChildren
      else
	DoChildren

    method vstmt _ = DoChildren

    method vinst instr =
      begin
	match instr with
	| Call (_, Lval lval, _, location)
	  when isWeightyLval hasDefinition hasPragmaWeightless weighty lval ->
	    raise (ContainsWeightyCall (location, lval))

	| Call (_, Lval lval, _, location) ->
	    ()

	| Call (_, callee, _, _) ->
	    ignore (bug "unexpected non-lval callee: %a" d_exp callee);
	    failwith "internal error"

	| _ -> ()

      end;
      SkipChildren
  end


type tester = lval -> bool


let collect file (fileInfo : FileInfo.container) =
  let hasDefinition = hasDefinition file in
  let hasPragmaWeightless = hasPragmaWeightless file in
  let weighty = new VarinfoSet.container in

  let prepopulate func info =
    if info.sites <> [] then
      begin
	weighty#add func.svar;
	if !debugWeighty then
	  Printf.eprintf "function %s is weighty: has sites\n" func.svar.vname
      end
  in
  fileInfo#iter prepopulate;

  let visitor = new visitor hasDefinition hasPragmaWeightless weighty in
  let refine madeProgress =
    let iterator = function
      | GFun (func, _) ->
	  begin
	    try
	      ignore (visitCilFunction visitor func)
	    with ContainsWeightyCall (location, callee) ->
	      weighty#add func.svar;
	      madeProgress := true;
	      if !debugWeighty then
		ignore (Pretty.eprintf "%a: function %s is weighty: has weighty call to %a@!"
			  d_loc location func.svar.vname d_lval callee)
	  end
      | _ -> ()
    in
    iterGlobals file iterator
  in
  Fixpoint.compute refine;
  isWeightyLval hasDefinition hasPragmaWeightless weighty
