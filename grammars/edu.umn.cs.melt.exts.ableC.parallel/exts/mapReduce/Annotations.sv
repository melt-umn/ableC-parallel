grammar edu:umn:cs:melt:exts:ableC:parallel:exts:mapReduce;

synthesized attribute syncBy :: Maybe<Qualifiers>;

nonterminal MapReduceAnnts with errors, env, controlStmtContext, bySystem,
  numParallelThreads, fusion, syncBy, pp;

abstract production consMapReduceAnnts
top::MapReduceAnnts ::= hd::MapReduceAnnt tl::MapReduceAnnts
{
  top.pp = ppConcat([hd.pp, semi(), space(), tl.pp]);

  top.bySystem = if hd.bySystem.isJust then hd.bySystem else tl.bySystem;
  top.numParallelThreads = 
    if hd.numParallelThreads.isJust then hd.numParallelThreads
    else tl.numParallelThreads;
  top.fusion = if hd.fusion.isJust then hd.fusion else tl.fusion;
  top.syncBy = if hd.syncBy.isJust then hd.syncBy else tl.syncBy;

  top.errors := hd.errors ++ tl.errors ++
    (if hd.bySystem.isJust && tl.bySystem.isJust
     then [err(hd.location, "Multiple map-reduce annotations specify a parallelism system")]
     else [])
    ++
    (if hd.numParallelThreads.isJust && tl.numParallelThreads.isJust
     then [err(hd.location, "Multiple map-reduce annotations specify the number of threads")]
     else [])
    ++
    (if hd.fusion.isJust && tl.fusion.isJust
    then [err(hd.location, "Multiple map-reduce annotations specify a fusion")]
    else [])
    ++
    (if hd.syncBy.isJust && tl.syncBy.isJust
    then [err(hd.location, "Multiple map-reduce annotations specify a synchronization system")]
    else []);
}

abstract production nilMapReduceAnnts
top::MapReduceAnnts ::=
{
  top.pp = notext();
  top.errors := [];
  top.bySystem = nothing();
  top.numParallelThreads = nothing();
  top.fusion = nothing();
  top.syncBy = nothing();
}

nonterminal MapReduceAnnt with errors, env, controlStmtContext, bySystem,
  numParallelThreads, fusion, syncBy, location, pp;

abstract production mapReduceParallelAnnt
top::MapReduceAnnt ::= annt::ParallelAnnotation
{
  top.pp = annt.pp;

  top.bySystem = annt.bySystem;
  top.numParallelThreads = annt.numParallelThreads;
  top.fusion = nothing();
  top.syncBy = nothing();

  top.errors := annt.errors ++
    (if !null(annt.publics)
     then [err(top.location, "public annotation not permitted on map-reduce")]
     else [])
    ++
    (if !null(annt.privates)
     then [err(top.location, "private annotation not permitted on map-reduce")]
     else [])
    ++
    (if !null(annt.globals)
     then [err(top.location, "global annotation not permitted on map-reduce")]
     else [])
    ++
    (if !null(annt.inGroups)
     then [err(top.location, "in annotation not permitted on map-reduce")]
     else []);
}

abstract production mapReduceFusionAnnt
top::MapReduceAnnt ::= fuse::Fusion
{
  top.pp = ppConcat([text("fuse"), space(), fuse.pp]);

  top.bySystem = nothing();
  top.numParallelThreads = nothing();
  top.fusion = just(fuse);
  top.syncBy = nothing();
  
  top.errors := [];
}

abstract production mapReduceSyncAnnt
top::MapReduceAnnt ::= sys::Qualifiers
{
  top.pp = ppConcat([text("sync-by"), space(), ppImplode(space(), sys.pps)]);

  top.bySystem = nothing();
  top.numParallelThreads = nothing();
  top.fusion = nothing();
  top.syncBy = just(sys);

  top.errors := [];
}

function toParallelAnnotations
ParallelAnnotations ::= annts::MapReduceAnnts
{
  return
    case annts of
    | nilMapReduceAnnts() -> nilParallelAnnotations()
    | consMapReduceAnnts(mapReduceParallelAnnt(a), tl) ->
        consParallelAnnotations(a, toParallelAnnotations(tl))
    | consMapReduceAnnts(_, tl) -> toParallelAnnotations(tl)
    end;
}

function removeFusion
MapReduceAnnts ::= annts::MapReduceAnnts
{
  return
    case annts of
    | nilMapReduceAnnts() -> nilMapReduceAnnts()
    | consMapReduceAnnts(mapReduceFusionAnnt(_), tl) ->
        removeFusion(tl)
    | consMapReduceAnnts(hd, tl) -> consMapReduceAnnts(hd, removeFusion(tl))
    end;
}
