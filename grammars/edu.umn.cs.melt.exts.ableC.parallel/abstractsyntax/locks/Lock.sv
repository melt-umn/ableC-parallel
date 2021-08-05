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

  top.ovrld:lEqProd = just(lockSetProd(sys, _, _, location=_));
  top.newProd = just(lockNewProd(_, location=_));
  top.deleteProd = sys.lockDeleteProd;
}

abstract production lockNewProd
top::Expr ::= args::Exprs
{
  forwards to errorExpr([err(top.location,
    "Constructing a lock can only occur on the rhs of an assignment")],
    location=top.location);
}

abstract production lockSetProd
top::Expr ::= sys::Decorated LockSystem lhs::Expr rhs::Expr
{
  top.pp = ppConcat([lhs.pp, text(" = "), rhs.pp]);

  forwards to 
    case rhs of
    | newExpr(_, args) -> sys.initializeLock(lhs, args, top.location)
    | _ -> errorExpr([err(top.location,
                    "Locks can only be assigned a constructed value (using new)")],
              location=top.location)
    end;
}
