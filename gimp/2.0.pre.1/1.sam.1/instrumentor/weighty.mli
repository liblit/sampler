open Cil


val assumeWeightlessExterns : bool ref


type tester = lval -> bool

val collect : file -> (fundec * 'a) list -> tester
