open Cil


class visitor =
  object
    inherit FunctionBodyVisitor.visitor

    val seen = new StmtSet.container
	
    val mutable forwards = []
    val mutable backwards = []
    method result = (forwards, backwards)

    method vstmt stmt =
      begin
	match stmt.skind with
	| Goto (destination, _) ->
	    if seen#mem !destination then
	      backwards <- stmt :: backwards
	    else
	      forwards <- stmt :: forwards
	| _ -> ()
      end;
      seen#add stmt;
      DoChildren
  end


let visit {sbody = sbody} =
  let visitor = new visitor in
  ignore (visitCilBlock (visitor :> cilVisitor) sbody);
  visitor#result
