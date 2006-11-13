open Cil


class visitor file =
  let counters = new Counters.builder file in

  object
    inherit Manager.visitor "branches" file as super

    val classifier = new BranchClassifier.visitor counters

    method private statementClassifier = classifier

    method private finalize =
      counters#finalize
  end
