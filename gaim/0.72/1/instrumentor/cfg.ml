open Cil


(* control flow successors following various types of execution *)
type context = {
    next : stmt option;			(* sequential fall-through *)
    break : stmt option;		(* loop or switch break *)
    continue : stmt option		(* loop continue *)
  }


(* clear out all edge lists and renumber all nodes *)
class prepare =
  object
    inherit FunctionBodyVisitor.visitor

    val mutable nextId = 0

    method vstmt statement =
      statement.succs <- [];
      statement.preds <- [];
      statement.sid <- nextId;
      nextId <- nextId + 1;
      DoChildren

    method vfunc func =
      let post func =
	func.smaxstmtid <- Some nextId;
	func
      in
      ChangeDoChildrenPost (func, post)
  end


let build func =
  (* add control flow edges between a pair of statements *)
  let link pred succ =

    (* insert one item into an ordered list *)
    let rec insert addition = function
      | [] ->
	  [addition]
      | (head :: tail) as sorted ->
	  if head.sid > addition.sid then
	    head :: (insert addition tail)
	  else if head.sid == addition.sid then
	    sorted
	  else
	    addition :: sorted
    in

    (* link up the statements *)
    pred.succs <- insert succ pred.succs;
    succ.preds <- insert pred succ.preds
  in

  (* link a statement to an optional successor *)
  let linkMaybe pred = function
    | Some succ -> link pred succ
    | None -> ()
  in

  (* link a statement to an optional (but required) successor *)
  let linkLoop pred = function
    | Some succ ->
	link pred succ
    | None ->
	Errormsg.s (errorLoc
		      (get_stmtLoc pred.skind)
		      "break or continue with no enclosing loop");
  in

  (* pick the next statement: first in list or inherited fall-through *)
  let pickNext inherited = function
    | [] -> inherited
    | first :: _ -> Some first
  in

  (* scan a statement block *)
  let rec scanBlock context block =
    scanStatements context block.bstmts

  (* scan a list of statements *)
  and scanStatements context = function
    | [] ->
	()
    | first :: rest ->
	let firstContext = {context with next = pickNext context.next rest} in
	scanStatement firstContext first;
	scanStatements context rest

  (* scan a single statement *)
  and scanStatement context statement =
    match statement.skind with
    | Instr _ ->
	(* fall through to next *)
	linkMaybe statement context.next

    | Return _ ->
	(* end of the line *)
	()

    | Goto (target, _) ->
	(* jump directly to target *)
	link statement !target

    | Break _ ->
	(* jump to current break target *)
	linkLoop statement context.break

    | Continue _ ->
	(* jump to current continue target *)
	linkLoop statement context.continue

    | If (_, thenBlock, elseBlock, _) ->
	(* continue in either subblock *)
	(* if subblock is empty, fall through to next statement *)
	linkMaybe statement (pickNext context.next thenBlock.bstmts);
	linkMaybe statement (pickNext context.next elseBlock.bstmts);

	(* each subblock falls through to next statement after "if" *)
	scanBlock context thenBlock;
	scanBlock context elseBlock

    | Switch (_, body, cases, location) ->
	(* continue in any of the case handlers *)
	List.iter (link statement) cases;

	(* fall through as well if no "default:" case *)
	begin
	  match context.next with
	  | None -> ()
	  | Some next ->
	      let hasDefault =
		let hasDefaultLabel case =
		  let isDefaultLabel = function
		    | Default _ -> true
		    | _ -> false
		  in
		  List.exists isDefaultLabel case.labels
		in	    
		List.exists hasDefaultLabel cases
	      in
	      if not hasDefault then
		link statement next
	end;

	(* breaks in body jump to statement after "switch" *)
	let switchContext = {context with break = context.next} in
	scanBlock switchContext body

    | Loop (body, location, _, _) ->
	(* fall through to top of loop, or self if loop body is empty *)
	linkMaybe statement (pickNext (Some statement) body.bstmts);

	(* loop is infinite, so body fall-through goes back to top *)
	(* break jumps to statement after loop *)
	(* continue jumps to top of loop for one more go-around *)
	let loopContext = {next = Some statement;
			   break = context.next;
			   continue = Some statement}
	in
	scanBlock loopContext body

    | Block body ->
	(* fall through to first substatement *)
	linkMaybe statement (pickNext context.next body.bstmts);

	(* block body falls through to statement after block *)
	scanBlock context body
  in

  (* away we go! *)
  ignore (visitCilFunction (new prepare) func);
  scanBlock {next = None; break = None; continue = None} func.sbody
