open Cil
open Arg


let main transformer =
  let phases =
    [
     Choices.phase;
     transformer;
     "RemoveUnusedTemps", (fun file -> Rmtmps.removeUnusedTemps file);
     Options.phase;
     "dump", dumpFile (new Printer.printer) stdout
   ]
  in
  
  initCIL ();
  parse Options.argspecs
    (TestHarness.doOne phases)
    ("Usage:" ^ Sys.executable_name ^ " [<flag> | <source>] ...")
