open Cil


class visitor : file ->
  object
    inherit PrepareDaikount.visitor

    method private statementClassifier : global -> fundec -> Classifier.visitor
  end
