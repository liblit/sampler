open Cil
open DescribedExpression
open SiteInfo


class builder file =
  object (self)
    inherit Tuples.builder file


    method bump func location result =
      let slice = self#addSiteInfo { location = location; fundec = func;
				     description = result.doc }
      in
      Bump.bump location result.exp slice
  end
