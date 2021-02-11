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

  top.ovrld:lEqProd = just(groupSetProd(sys, _, _, location=_));
  top.newProd = just(groupNewProd(_, location=_));
  top.deleteProd = sys.groupDeleteProd;
}

abstract production groupNewProd
top::Expr ::= args::Exprs
{
  forwards to errorExpr([err(top.location,
    "Constructing a group can only occur on the rhs of an assignment")],
    location=top.location);
}

abstract production groupSetProd
top::Expr ::= sys::Decorated SyncSystem lhs::Expr rhs::Expr
{
  top.pp = ppConcat([lhs.pp, text(" = "), rhs.pp]);

  forwards to 
    case rhs of
    | newExpr(_, args) -> sys.initializeGroup(lhs, args, top.location)
    | _ -> errorExpr([err(top.location, 
                    "Groups can only be assigned a constructed value (using new)")],
              location=top.location)
    end;
}
