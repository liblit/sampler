open Cil


class visitor file =
  let logger = FindLogger.find file in
  
  object inherit TransformVisitor.visitor file
      
    method weigh = Weigh.weigh
    method insertSkips = new Skips.visitor
    method insertLogs = new Logs.visitor logger
  end


let phase =
  "Transform",
  fun file ->
    visitCilFileSameGlobals (new visitor file :> cilVisitor) file
