open Calls
open Cil
open DescribedExpression
open Interesting


class visitor (tuples : ReturnTuples.builder) func =
  object (self)
    inherit Classifier.visitor func as super

    method private normalize =
      StoreReturns.visit func;
      super#normalize

    method vstmt stmt =
      match stmt.skind with
      | Instr [Call (Some result, callee, args, location)]
	when self#includedStatement stmt ->
	  let info = super#prepatchCall stmt in
	  let resultType, _, _, _ = splitFunctionType (typeOf callee) in
	  if isInterestingType resultType then
	    begin
	      let exp = Lval result in
	      let desc = d_exp () callee in
	      let bump = tuples#bump func location { exp = exp; doc = desc } in
	      sites <- info.site :: sites;
	      let call = mkStmt stmt.skind in
	      info.site.skind <- bump;
	    end;
	  SkipChildren

      | _ ->
	  super#vstmt stmt
  end
