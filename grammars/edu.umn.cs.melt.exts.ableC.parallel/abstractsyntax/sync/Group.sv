grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:sync;

abstract production groupTypeExpr
top::BaseTypeExpr ::= q::Qualifiers
{
  top.pp = ppConcat([ppImplode(space(), q.pps), text("group")]);

  local partitionQualifiers :: Pair<[Qualifier] [Qualifier]> =
    partition(\q::Qualifier -> q.syncSystem.isJust, q.qualifiers);

  local syncQuals :: [Qualifier] = partitionQualifiers.fst;
  local otherQuals :: [Qualifier] = partitionQualifiers.snd;

  -- TODO: Location
  local localErrors :: [Message] =
    if null(syncQuals) || !null(tail(syncQuals))
    then [err(builtin, "An object of type 'group' must have a single qualifier specifying the implementation")]
    else [];

  local syncSystem :: SyncSystem = head(syncQuals).syncSystem.fromJust;
  syncSystem.env = top.env;

  forwards to
    if !null(localErrors)
    then errorTypeExpr(localErrors)
    else extTypeExpr(foldQualifier(otherQuals),
      groupType(syncSystem));
}

abstract production groupType
top::ExtType ::= sys::Decorated SyncSystem
{
  propagate canonicalType;

  top.pp = ppConcat([text(sys.parName), space(), text("group")]);
  top.mangledName = s"group_${sys.parName}";
  top.isEqualTo =
    \ other::ExtType ->
      case other of
      | groupType(s) -> s.parName == sys.parName
      | _ -> false
      end;

  local sysType :: Type = sys.groupType;
  sysType.addedTypeQualifiers = top.givenQualifiers.qualifiers;

  top.host = sysType.withTypeQualifiers;

  top.newProd = sys.groupNewProd;
  top.deleteProd = sys.groupDeleteProd;
}
