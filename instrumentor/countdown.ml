open Cil


type token = lval * exp


let findGlobal =
  let predicate = function
    | TInt _ -> true
    | _ -> false
  in
  FindGlobal.find predicate "nextEventCountdown"


let findReset = FindFunction.find "resetCountdown"


let find file = (findGlobal file, findReset file)


class countdown (global, reset) fundec =
  let local = var (makeTempVar fundec ~name:"localCountdown" uintType) in
  
  object (self)
    method decrement location =
      Instr [Set (local, increm (Lval local) (-1), location)]

    method beforeCall location =
      Set (global, (Lval local), location)

    method afterCall location =
      Set (local, (Lval global), location)

    method checkThreshold location weight instrumented original =
      let within = kinteger IUInt weight in
      let predicate = BinOp (Gt, Lval local, within, intType) in
      let choice = If (predicate, original, instrumented, location) in
      Choices.add choice;
      choice

    method decrementAndCheckZero skind =
      let location = get_stmtLoc skind in
      let callReset = mkStmtOneInstr (Call (Some local, reset, [], location)) in
      Block (mkBlock [ mkStmt (self#decrement location);
			mkStmt (If (BinOp (Eq, Lval local, zero, intType),
				    mkBlock [ mkStmt skind; callReset ],
				    mkBlock [],
				    location)) ])
  end
