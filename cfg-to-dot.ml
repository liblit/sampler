open Cil
open Dotify
open Foreach
open Pretty
  

class visitor = object
  inherit nopCilVisitor
      
  method vfunc func =
    let (_, stmts) = Cfg.cfg func in
    foreach stmts begin
      fun stmt ->
	fprint stdout 80
	  (indent 2 (d_node () stmt
		       ++ seq nil (d_edge () stmt) stmt.succs))
    end;
    
    SkipChildren
      
end
    
;;

print_string "digraph CFG {\n";
ignore(TestHarness.main [new visitor]);
print_string "}\n"
