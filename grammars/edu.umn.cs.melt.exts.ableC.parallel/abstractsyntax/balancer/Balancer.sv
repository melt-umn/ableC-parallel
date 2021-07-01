grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:balancer;

abstract production balancerTypeExpr
top::BaseTypeExpr ::= q::Qualifiers
{
  top.pp = ppConcat([ppImplode(space(), q.pps), text("balancer")]);

  local partitionQualifiers :: Pair<[Qualifier] [Qualifier]> = 
    partition(\q::Qualifier -> q.balancerSystem.isJust, q.qualifiers);

  local balancerQuals :: [Qualifier] = partitionQualifiers.fst;
  local otherQuals :: [Qualifier] = partitionQualifiers.snd;

  -- TODO: Location
  local localErrors::[Message] =
    if null(balancerQuals) || !null(tail(balancerQuals))
    then [err(builtin, "An object of type 'balancer' must have a single qualifier specifying the system")]
    else [];

  local balancerSystem :: BalancerSystem =
    head(balancerQuals).balancerSystem.fromJust;

  forwards to 
    if !null(localErrors)
    then errorTypeExpr(localErrors)
    else extTypeExpr(foldQualifier(otherQuals),
      balancerType(balancerSystem));
}

abstract production balancerType
top::ExtType ::= sys::BalancerSystem
{
  propagate canonicalType;

  top.pp = ppConcat([text(sys.parName), space(), text("balancer")]);
  top.mangledName = s"balancer_${sys.parName}";
  top.isEqualTo =
    \ other::ExtType ->
      case other of
      | balancerType(s) -> s.parName == sys.parName
      | _ -> false
      end;

  top.host =
    (decorate
      refIdExtType(structSEU(), just("__balancer"),
        "edu:umn:cs:melt:exts:ableC:parallel:exts:balancer:balancer")
    with {givenQualifiers=nilQualifier();}).host;
  top.newProd = sys.newProd;
  top.deleteProd = sys.deleteProd;
}
