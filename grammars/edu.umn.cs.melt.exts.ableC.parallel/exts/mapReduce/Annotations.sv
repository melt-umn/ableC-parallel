grammar edu:umn:cs:melt:exts:ableC:parallel:exts:mapReduce;

synthesized attribute syncBy :: Maybe<Qualifiers>;
synthesized attribute parComb :: Maybe<(Name, Name, Expr)>;

nonterminal MapReduceAnnts with errors, env, controlStmtContext, bySystem,
  numParallelThreads, fusion, syncBy, parComb, pp;

abstract production consMapReduceAnnts
top::MapReduceAnnts ::= hd::MapReduceAnnt tl::MapReduceAnnts
{
  top.pp = ppConcat([hd.pp, semi(), space(), tl.pp]);

  propagate controlStmtContext, env;

  top.bySystem = if hd.bySystem.isJust then hd.bySystem else tl.bySystem;
  top.numParallelThreads = 
    if hd.numParallelThreads.isJust then hd.numParallelThreads
    else tl.numParallelThreads;
  top.fusion = if hd.fusion.isJust then hd.fusion else tl.fusion;
  top.syncBy = if hd.syncBy.isJust then hd.syncBy else tl.syncBy;
  top.parComb = if hd.parComb.isJust then hd.parComb else tl.parComb;

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
    else [])
    ++
    (if hd.parComb.isJust && tl.parComb.isJust
    then [err(hd.location, "Multiple map-reduce annotations specify a parallel combining operator")]
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
  top.parComb = nothing();
}

nonterminal MapReduceAnnt with errors, env, controlStmtContext, bySystem,
  numParallelThreads, fusion, syncBy, parComb, location, pp;

aspect default production
top::MapReduceAnnt ::=
{
  top.bySystem = nothing();
  top.numParallelThreads = nothing();
  top.fusion = nothing();
  top.syncBy = nothing();
  top.parComb = nothing();
  top.errors := [];
}

abstract production mapReduceParallelAnnt
top::MapReduceAnnt ::= annt::ParallelAnnotation
{
  top.pp = annt.pp;

  propagate controlStmtContext, env;

  top.bySystem = annt.bySystem;
  top.numParallelThreads = annt.numParallelThreads;

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

  top.fusion = just(fuse);
}

abstract production mapReduceSyncAnnt
top::MapReduceAnnt ::= sys::Qualifiers
{
  top.pp = ppConcat([text("sync-by"), space(), ppImplode(space(), sys.pps)]);

  top.syncBy = just(sys);
}

abstract production mapReduceParCombAnnt
top::MapReduceAnnt ::= v1::Name v2::Name bd::Expr
{
  top.pp = ppConcat([text("par-comb"), space(), text("\\"), v1.pp, space(),
              v2.pp, space(), text("->"), space(), bd.pp]);

  top.parComb = just((v1, v2, new(bd)));
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
