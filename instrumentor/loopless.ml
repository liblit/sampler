open Cil


exception FoundLoop

let assumeLooplessExterns =
  Options.registerBoolean
    ~flag:"assume-loopless-externs"
    ~desc:"assume that functions defined elsewhere have no loops or recursion"
    ~ident:"AssumeLooplessExterns"
    ~default:false

let assumeLooplessLibraries =
  Options.registerBoolean
    ~flag:"assume-loopless-libraries"
    ~desc:"assume that functions defined in libraries have no loops or recursion"
    ~ident:"AssumeLooplessLibraries"
    ~default:true


class visitor loopless changed =
  object (self)
    inherit FunctionBodyVisitor.visitor

    val mutable definitelyLoopless = true

    method vfunc func =
      if not (loopless#mem func.svar.vname) then
	begin
	  try
	    definitelyLoopless <- true;
	    ignore (visitCilBlock (self :> cilVisitor) func.sbody);
	    if definitelyLoopless then
	      begin
		loopless#add func.svar.vname true;
		changed := true
	      end
	  with FoundLoop ->
	    loopless#add func.svar.vname false;
	    changed := true
	end;
      SkipChildren

    method vstmt _ =
      DoChildren

    method vinst inst =
      begin
	match inst with
	| Call (_, Lval (Var callee, NoOffset), _, _) ->
	    begin
	      try
		if not (loopless#find callee.vname) then
		  raise FoundLoop
	      with Not_found ->
		definitelyLoopless <- false
	    end
	| Call _ ->
	    raise FoundLoop
	| _ ->
	    ()
      end;
      SkipChildren
  end


let addLibraries loopless =
  Libraries.functions#iter (fun name -> loopless#add name true);
  List.iter loopless#remove ["bsearch"; "qsort";
			     "setjmp"; "__sigsetjmp"; "_setjmp";
			     "__libc_longjmp"; "__libc_siglongjmp";
			     "_longjmp"; "longjmp"; "siglongjmp"]


let addExterns loopless file =
  iterGlobals file
    begin
      function
	| GVarDecl ({ vtype = TFun _; vname = vname }, _) ->
	    loopless#add vname true
	| _ -> ()
    end;

  iterGlobals file
    begin
      function
	| GFun ({ svar = { vname = vname }}, _) ->
	    loopless#remove vname
	| _ -> ()
    end


let loopless file =
  let loopless = new StringMap.container in
  if !assumeLooplessExterns then addExterns loopless file;
  if !assumeLooplessLibraries then addLibraries loopless;

  let considerGlobal = function
    | GFun (func, _) ->
	prepareCFG func;
	RemoveLoops.visit func;
	ignore (computeCFGInfo func false);
	if (ClassifyJumps.visit func).ClassifyJumps.backward != [] then
	  loopless#add func.svar.vname false
    | _ ->
	()
  in
  iterGlobals file considerGlobal;

  let changed = ref false in
  let visitor = new visitor loopless changed in
  let iterate () = visitCilFile visitor file in
  iterate ();
  while !changed do
    changed := false;
    iterate ()
  done;

  fun varinfo ->
    try
      loopless#find varinfo.vname
    with Not_found ->
      false


;;


initCIL ();

let process filename =
  let file = Frontc.parse filename () in
  let loopless = loopless file in
  let considerGlobal = function
    | GFun ({svar = varinfo}, _) ->
	Printf.printf "%s\t%b\n" varinfo.vname (loopless varinfo)
    | _ ->
	()
  in
  iterGlobals file considerGlobal
in
let filenames = List.tl (Array.to_list Sys.argv) in
List.iter process filenames
