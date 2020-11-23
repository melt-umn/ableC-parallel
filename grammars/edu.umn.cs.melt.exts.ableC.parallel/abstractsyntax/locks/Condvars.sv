grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:locks;

abstract production condvarTypeExpr
top::BaseTypeExpr ::= q::Qualifiers
{
  top.pp = ppConcat([ppImplode(space(), q.pps), text("condvar")]);

  local partitionQualifiers :: Pair<[Qualifier] [Qualifier]> =
    partition(\q::Qualifier -> q.lockSystem.isJust, q.qualifiers);

  local lockQuals :: [Qualifier] = partitionQualifiers.fst;
  local otherQuals :: [Qualifier] = partitionQualifiers.snd;

  -- TODO: Location
  local localErrors :: [Message] =
    if null(lockQuals) || !null(tail(lockQuals))
    then [err(builtin, "An object of type 'condvar' must have a single qualifier specifying the system")]
    else [];

  local lockSystem :: LockSystem = head(lockQuals).lockSystem.fromJust;
  lockSystem.env = top.env;

  forwards to
    if !null(localErrors)
    then errorTypeExpr(localErrors)
    else extTypeExpr(foldQualifier(otherQuals),
      condvarType(lockSystem));
}

abstract production condvarType
top::ExtType ::= sys::Decorated LockSystem
{
  propagate canonicalType;

  top.pp = ppConcat([text(sys.parName), space(), text("condvar")]);
  top.mangledName = s"condvar_${sys.parName}";
  top.isEqualTo =
    \ other::ExtType ->
      case other of
      | condvarType(s) -> s.parName == sys.parName
      | _ -> false
      end;

  local condType :: Type = sys.condType;
  condType.addedTypeQualifiers = top.givenQualifiers.qualifiers;

  top.host = condType.withTypeQualifiers;

  top.newProd = sys.condvarNewProd;
  top.deleteProd = sys.condvarDeleteProd;
}
