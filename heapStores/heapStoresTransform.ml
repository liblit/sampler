open Cil


class visitor file = object
  inherit TransformVisitor.visitor file as super

  method weigh = Stores.count_stmt
  method insertSkips = new SkipWrites.visitor
  method insertLogs = new Instrument.visitor

  method vfunc func =
    Simplify.visit func;
    super#vfunc func
end


let phase =
  "Transform",
  fun file ->
    visitCilFileSameGlobals (new visitor file :> cilVisitor) file
