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

  top.ovrld:lEqProd = just(threadSetProd(sys, _, _, location=_));
  top.newProd = just(threadNewProd(_, location=_));
  top.deleteProd = sys.threadDeleteProd;
}

abstract production threadNewProd
top::Expr ::= args::Exprs
{
  forwards to errorExpr([err(top.location,
    "Constructing a thread can only occur on the rhs of an assignment")],
    location=top.location);
}

abstract production threadSetProd
top::Expr ::= sys::Decorated SyncSystem lhs::Expr rhs::Expr
{
  top.pp = ppConcat([lhs.pp, text(" = "), rhs.pp]);

  propagate controlStmtContext, env;

  forwards to 
    case rhs of
    | newExpr(_, args) -> sys.initializeThread(lhs, args, top.location)
    | _ -> errorExpr([err(top.location, 
                    "Thread can only be assigned a constructed value (using new)")],
              location=top.location)
    end;
}
