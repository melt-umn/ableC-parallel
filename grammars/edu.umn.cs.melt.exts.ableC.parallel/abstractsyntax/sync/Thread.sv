grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:sync;

abstract production threadTypeExpr
top::BaseTypeExpr ::= q::Qualifiers
{
  top.pp = ppConcat([ppImplode(space(), q.pps), text("thread")]);

  local partitionQualifiers :: Pair<[Qualifier] [Qualifier]> =
    partition(\q::Qualifier -> q.syncSystem.isJust, q.qualifiers);

  local syncQuals :: [Qualifier] = partitionQualifiers.fst;
  local otherQuals :: [Qualifier] = partitionQualifiers.snd;

  -- TODO: Location
  local localErrors :: [Message] =
    if null(syncQuals) || !null(tail(syncQuals))
    then [err(builtin, "An object of type 'thread' must have a single qualifier specifying the implementation")]
    else [];

  local syncSystem :: SyncSystem = head(syncQuals).syncSystem.fromJust;
  syncSystem.env = top.env;

  forwards to
    if !null(localErrors)
    then errorTypeExpr(localErrors)
    else extTypeExpr(foldQualifier(otherQuals),
      threadType(syncSystem));
}

abstract production threadType
top::ExtType ::= sys::Decorated SyncSystem
{
  propagate canonicalType;

  top.pp = ppConcat([text(sys.parName), space(), text("thread")]);
  top.mangledName = s"thread_${sys.parName}";
  top.isEqualTo =
    \ other::ExtType ->
      case other of
      | threadType(s) -> s.parName == sys.parName
      | _ -> false
      end;

  local sysType :: Type = sys.threadType;
  sysType.addedTypeQualifiers = top.givenQualifiers.qualifiers;

  top.host = sysType.withTypeQualifiers;

  top.newProd = sys.threadNewProd;
  top.deleteProd = sys.threadDeleteProd;
}
