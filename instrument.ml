open Cil


let logWrite =
  let f = emptyFunction "logWrite" in
  let arg name typ = ignore (makeFormalVar f ~where:"$" name typ) in
  arg "file" charConstPtrType;
  arg "line" uintType;
  arg "address" voidPtrType;
  arg "size" uintType;
  arg "data" voidPtrType;
  f.svar
    

let addPrototype file =
  file.globals <- GVarDecl (logWrite, logWrite.vdecl) :: file.globals


let makeLval = function
  | Lval lval -> lval
  | _ -> failwith "weird expression"
	
	
class visitor = object
  inherit FunctionBodyVisitor.visitor
      
  method vstmt _ = DoChildren

  method vinst inst =
    match inst with
    | Set((Mem addr, _), data, location) as original ->
	Printf.eprintf "%s:%i: adding instrumentation point\n"
	  location.file location.line;
	ChangeTo [Call (None, Lval (var logWrite),
			[mkString location.file;
			 kinteger IUInt location.line;
			 mkCast addr voidPtrType;
			 SizeOf(typeOf data);
			 mkCast (mkAddrOf (makeLval data)) voidPtrType],
			location);
		  original]
    | _ -> SkipChildren
end


let phase _ =
  ("Instrument", fun file ->
    addPrototype file;
    visitCilFileSameGlobals new visitor file)
