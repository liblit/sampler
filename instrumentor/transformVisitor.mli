open Cil


val removeDeadCode : bool ref


class virtual visitor : file -> object
  inherit cilVisitor
  method private virtual collector : fundec -> Collector.visitor
  method private prepatchCalls : fundec -> Calls.placeholders
end
