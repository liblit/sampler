open Cil
open Printf


let rec weighPaths headers =
  
  let cache = new MapClass.container 0 in

  let rec subweight node succ =
    if headers#mem (node, succ) then
      0
    else
      weight succ

  and weight node =
    try cache#find node with
      Not_found ->
	printf "      no cached weight for %i\n" node.sid;
	let myWeight = Stores.count_stmt node in
	let childWeights = List.map (subweight node) node.succs in
	let maxChildWeight = List.fold_left max 0 childWeights in
	let total = myWeight + maxChildWeight in
	cache#add node total;
	total
  in

  let weights = new MapClass.container headers#size in

  headers#iter begin
    fun (s, destination) ->
      printf "    weighing (%i, %i)\n" s.sid destination.sid;
      weights#add destination (weight destination)
  end;

  weights
    
    
(**********************************************************************)
	  
	  
class visitor = object
  inherit nopCilVisitor
      
  method vfunc func =
    printf "  weighing %s()" func.svar.vname;
    print_newline ();
    
    let cfg = Cfg.cfg func in
    let headers = CollectHeaders.collectHeaders cfg in
    printf "    collected %i headers\n" headers#size;
    let weights = weighPaths headers in
    print_endline "    weighed paths";
    
    let printWeight node weight =
      printf "    weight below %i: %i" node.sid weight;
      print_newline ()
    in

    weights#iter printWeight;
    SkipChildren
end
