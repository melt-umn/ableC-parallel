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

  top.ovrld:lEqProd = just(condvarSetProd(sys, _, _, location=_));
  top.newProd = just(condvarNewProd(_, location=_));
  top.deleteProd = sys.condvarDeleteProd;
}

abstract production condvarNewProd
top::Expr ::= args::Exprs
{
  forwards to errorExpr([err(top.location,
    "Constructing a condvar can only occur on the rhs of an assignment")],
    location=top.location);
}

abstract production condvarSetProd
top::Expr ::= sys::Decorated LockSystem lhs::Expr rhs::Expr
{
  top.pp = ppConcat([lhs.pp, text(" = "), rhs.pp]);

  propagate controlStmtContext, env;

  forwards to 
    case rhs of
    | newExpr(_, args) -> sys.initializeCondvar(lhs, args, top.location)
    | _ -> errorExpr([err(top.location, 
                    "Condvars can only be assigned a constructed value (using new)")],
              location=top.location)
    end;
}
