open Cil


let find =
  let predicate = function
    | {vname = "nextLogCountdown"; vtype = TInt _} -> true
    | _ -> false
  in
  FindGlobal.find predicate
