grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel;

synthesized attribute parSystem::Maybe<ParallelSystem> occurs on Qualifier;

aspect default production
top::Qualifier ::=
{
  top.parSystem = nothing();
}

abstract production parallelTypeExpr
top::BaseTypeExpr ::= q::Qualifiers
{
  top.pp = ppConcat([ppImplode(space(), q.pps), text("parallel")]);

  local partitionQualifiers :: Pair<[Qualifier] [Qualifier]> = 
    partition(\q::Qualifier -> q.parSystem.isJust, q.qualifiers);

  local parallelQuals :: [Qualifier] = partitionQualifiers.fst;
  local otherQuals :: [Qualifier] = partitionQualifiers.snd;

  -- TODO: Location
  local localErrors::[Message] =
    if null(parallelQuals) || !null(tail(parallelQuals))
    then [err(builtin, "An object of type 'parallel' must have a single qualifier specifying the system")]
    else [];

  local parSystem :: ParallelSystem = head(parallelQuals).parSystem.fromJust;

  forwards to 
    if !null(localErrors)
    then errorTypeExpr(localErrors)
    else extTypeExpr(foldQualifier(otherQuals),
      parallelType(parSystem));
}

abstract production parallelType
top::ExtType ::= sys::ParallelSystem
{
  propagate canonicalType;

  top.pp = ppConcat([text(sys.parName), space(), text("parallel")]);
  top.mangledName = s"parallel_${sys.parName}";
  top.isEqualTo =
    \ other::ExtType ->
      case other of
      | parallelType(s) -> s.parName == sys.parName
      | _ -> false
      end;

  top.host = 
    pointerType(nilQualifier(),
      (decorate 
        refIdExtType(structSEU(), 
          just("__ableC_system_info"), 
          "edu:umn:cs:melt:exts:ableC:parallel:system-info")
      with {givenQualifiers=top.givenQualifiers;}).host
    );
  
  top.newProd = sys.newProd;
  top.deleteProd = sys.deleteProd;
}
