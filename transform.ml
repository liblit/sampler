open Cil
open Printf


class visitor = object
  inherit FunctionBodyVisitor.visitor

  method vfunc func =
    prepareCFG func;
    RemoveLoops.visit func;
    let afterCalls = AfterCalls.split func in
    ignore (computeCFGInfo func false);

    let forwardJumps, backwardJumps = ClassifyJumps.visit func in
    let entry = FunctionEntry.find func in
    let headers = entry :: backwardJumps @ afterCalls in
    let weights = WeighPaths.weigh headers in
    
    let instrumented, clones = Duplicate.duplicateBody func in
    
    ForwardJumps.patch clones forwardJumps;
    BackwardJumps.patch clones weights backwardJumps;
    AfterCalls.patch clones weights afterCalls;
    
    SkipWrites.visit func;
    FunctionEntry.patch func weights instrumented;
    InstrumentWrites.visit func instrumented;
    
    SkipChildren
end


let phase =
  "Transform",
  visitCilFileSameGlobals new visitor
