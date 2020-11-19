grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:locks;

abstract production lockTypeExpr
top::BaseTypeExpr ::= q::Qualifiers
{
  top.pp = ppConcat([ppImplode(space(), q.pps), text("lock")]);

  local partitionQualifiers :: Pair<[Qualifier] [Qualifier]> =
    partition(\q::Qualifier -> q.lockSystem.isJust, q.qualifiers);

  local lockQuals :: [Qualifier] = partitionQualifiers.fst;
  local otherQuals :: [Qualifier] = partitionQualifiers.snd;

  -- TODO: Location
  local localErrors :: [Message] =
    if null(lockQuals) || !null(tail(lockQuals))
    then [err(builtin, "An object of type 'lock' must have a single qualifier specifying the system")]
    else [];

  local lockSystem :: LockSystem = head(lockQuals).lockSystem.fromJust;
  lockSystem.env = top.env;

  forwards to
    if !null(localErrors)
    then errorTypeExpr(localErrors)
    else extTypeExpr(foldQualifier(otherQuals),
      lockType(lockSystem));
}

abstract production lockType
top::ExtType ::= sys::Decorated LockSystem
{
  propagate canonicalType;

  top.pp = ppConcat([text(sys.parName), space(), text("lock")]);
  top.mangledName = s"lock_${sys.parName}";
  top.isEqualTo =
    \ other::ExtType ->
      case other of
      | lockType(s) -> s.parName == sys.parName
      | _ -> false
      end;

  local sysType :: Type = sys.lockType;
  sysType.addedTypeQualifiers = top.givenQualifiers.qualifiers;

  top.host = sysType.withTypeQualifiers;
}
