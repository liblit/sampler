open Cil
open Pretty


val instr_what : instr -> string
val stmt_what : stmtkind -> string
val stmt_describe : stmtkind -> string

val d_stmt : unit -> stmt -> doc
val d_stmts : unit -> stmt list -> doc
val d_labels : unit -> stmt -> doc

val print_stmts : stmt list -> unit
val warn : stmt -> string -> unit

