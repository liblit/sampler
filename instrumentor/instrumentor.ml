open Cil


let sample =
  Options.registerBoolean
    ~flag:"sample"
    ~desc:"randomly sample instrumentation sites at run time"
    ~ident:"Sample"
    ~default:true


let schemes = ref []


let addScheme scheme =
  schemes := scheme :: !schemes


let phase =
  "instrumening",
  fun file ->
    Dynamic.analyze file;
    FunctionFilter.filter#collectPragmas file;

    let schemes = List.map (fun scheme -> scheme file) !schemes in
    List.iter (fun scheme -> scheme#findSites) schemes;
    let allSites = Site.enactAll () in

    let digest = lazy (Digest.file file.fileName) in
    List.iter (fun scheme -> scheme#embedInfo digest) schemes;
    EmbedCFG.visit file digest;

    if !sample then
      begin
	let tester = Weighty.collect file allSites in
	let countdown = new Countdown.countdown file in
	TestHarness.time "  applying sampling transformation"
	  (fun () -> Transform.visit tester allSites countdown)
      end
