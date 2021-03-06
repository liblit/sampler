open SchemeName


let name = {
  flag = "function-entries";
  prefix = "functionEntries";
  code = "E";
  ident = "FunctionEntries";
}


class c file : Scheme.c =
  let counters = new Counters.manager name file in
  object
    val finder = new FunctionEntryFinder.visitor counters

    method private findAllSites =
      Scanners.iterFuncs file
	(fun func ->
	  ignore (Cil.visitCilFunction finder func));
      counters#patch

    method saveSiteInfo = counters#saveSiteInfo
  end


let factory = SchemeFactory.build name new c
