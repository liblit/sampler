open Cil
open Foreach


class visitor = object
  inherit FunctionBodyVisitor.visitor
      
  method vfunc func =
    let (root, _) = Cfg.cfg func in
    
    let backEdges = new EdgeSet.container and
	arrived = new StmtSet.container and
	departed = new StmtSet.container in
    
    let rec explore stmt =
      arrived#add stmt;
      foreach stmt.succs begin
	fun succ ->
	  if not (arrived#mem succ) then
	    explore succ
	  else if not (departed#mem succ) then
	    backEdges#add (stmt, succ)
      end;
      departed#add stmt
    in
    
    explore root;
    
    backEdges#iter begin
      fun (src, dst) ->
	Printf.printf "back edge from CFG #%i to CFG #%i\n" src.sid dst.sid
    end;
    
    SkipChildren
end
    
;;

ignore(TestHarness.main ["FindBackEdges", visitCilFileSameGlobals new visitor])
