class visitor file =
  let collector = new Collector.visitor file in

  object
    inherit Manager.visitor file

    method private statementClassifier = collector
  end
