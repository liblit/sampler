open Cil
open Str


type classification = Check | Fail | Generic


let classifyByName = function
    (* include/ccuredcheck.h *)
  | "__CHECK_RETURNPTR"
  | "__CHECK_STOREPTR"
  | "__CHECK_FUNCTIONPOINTER"
  | "__CHECK_FSEQ2SAFE"
  | "__CHECK_FSEQALIGN"
  | "__CHECK_SEQALIGN"
  | "__CHECK_SEQ2SAFE"
  | "__CHECK_BOUNDS_LEN"
  | "__CHECK_INDEXALIGN"
  | "__CHECK_GEU"
  | "__CHECK_SEQ2FSEQ"
  | "__CHECK_POSITIVE"
  | "__CHECK_FSEQARITH"
  | "__CHECK_FSEQARITH2SAFE"
  | "__CHECK_NULL"
  | "__CHECK_RTTICAST"
  | "CHECK_UNIONTAG"
  | "__CHECK_WILDPOINTERREAD"
    (* lib/ccuredlib.c *)
  | "wildp_verify_atleast"
  | "wildp_write_atleast"
  | "__ccured_verify_nul"
  | "wildp_verify_nul"
  | "seqp_verify_atleast"
  | "fseqp_verify_atleast"
  | "DO_CHECK"
  | "CHECK_FORMATARGS"
  | "CHECK_FORMATARGS_w"
  | "__bounds_check_w"
  | "__bounds_check_q"
  | "__verify_nul_q"
  | "__read_at_least_q"
  | "__write_at_least_q"
  | "__bounds_check_f"
  | "__verify_nul_f"
  | "__read_at_least_f"
  | "__write_at_least_f"
  | "__verify_nul_Q"
  | "__write_at_least_Q"
  | "__read_at_least_Q"
  | "__verify_nul_F"
  | "__write_at_least_F"
  | "__read_at_least_F"
  | "__bounds_check_i"
  | "__write_at_least_i" ->
      Check
  | "fp_fail"
  | "fp_fail_str"
  | "fp_fail_w"
  | "lbound_or_ubound_fail"
  | "ubound_or_non_pointer_fail" ->
      Fail
  | _ ->
      Generic


let rec classifyStatement = function
  | Instr [Call (None, Lval (Var {vname = vname}, NoOffset), _, location)] ->
      classifyByName vname

  | Instr (_ :: _ :: _) ->
      failwith "instr should have been atomized"

  | If (_, { battrs = []; bstmts = [{skind = consequence}] }, { battrs = []; bstmts = [] }, _)
  | If (_, { battrs = []; bstmts = [] }, { battrs = []; bstmts = [{skind = consequence}] }, _)
    ->
      begin
	match classifyStatement consequence with
	| Check
	| Fail ->
	    Check
	| Generic ->
	    Generic
      end

  | If (_,
	{ battrs = []; bstmts = [{skind = consequence}] },
	{ battrs = []; bstmts = [{skind = alternative}] }, _)
    ->
      begin
	match
	  classifyStatement consequence,
	  classifyStatement alternative
	with
	| (Check | Fail), (Check | Fail) -> Check
	| _ -> Generic
      end

  | _ ->
      Generic
