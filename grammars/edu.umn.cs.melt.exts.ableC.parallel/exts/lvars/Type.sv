grammar edu:umn:cs:melt:exts:ableC:parallel:exts:lvars;

abstract production lvarTypeExpr
top::BaseTypeExpr ::= q::Qualifiers inner::TypeName loc::Location
{
  top.pp = ppConcat([ppImplode(space(), q.pps), space(),
                    text("lvar<"), inner.pp, text(">")]);

  propagate controlStmtContext, env;

  local partitionQualifiers :: Pair<[Qualifier] [Qualifier]> =
    partition(\q::Qualifier -> q.lockSystem.isJust, q.qualifiers);

  local lockQuals :: [Qualifier] = partitionQualifiers.fst;
  local otherQuals :: [Qualifier] = partitionQualifiers.snd;

  local localErrors :: [Message] =
    inner.errors
    ++
    (if null(lockQuals) || !null(tail(lockQuals))
     then [err(loc, "An 'lvar' must have a single qualifier specifying the synchronization implementation")]
     else []);
  
  local lockSystem :: LockSystem = head(lockQuals).lockSystem.fromJust;
  lockSystem.env = top.env;

  local mangledName :: String =
    s"${lockSystem.parName}_lvar_${inner.typerep.mangledName}";
  
  forwards to
    if !null(localErrors)
    then errorTypeExpr(localErrors)
    else
      injectGlobalDeclsTypeExpr(
        foldDecl(
          lvarTypeDecl(lockSystem, inner, mangledName, loc) :: inner.decls
        ),
        extTypeExpr(foldQualifier(otherQuals),
          lvarType(lockSystem, inner.typerep, top.pp, mangledName)));
}

abstract production lvarTypeDecl
top::Decl ::= sys::LockSystem inner::TypeName mangledName::String loc::Location
{
  top.pp = text("/* lvar type generated struct */");

  propagate controlStmtContext, env;

  forwards to
    maybeTagDecl(
      mangledName,
      ableC_Decl {
        struct __attribute__((refId($stringLiteralExpr{s"edu:umn:cs:melt:exts:ableC:parallel:exts:lvars:${mangledName}"}))) $name{mangledName} {
          inst Value<$directTypeExpr{inner.typerep}> value;
          void (*lub)(inst Value<$directTypeExpr{inner.typerep}>*, $directTypeExpr{inner.typerep});
          int frozen;

          $directTypeExpr{sys.lockType} access;
          $directTypeExpr{sys.condType} wait;
        };
      }
    );
}

abstract production lvarType
top::ExtType ::= sys::LockSystem inner::Type pp::Document mangledName::String
{
  propagate canonicalType;
  top.pp = pp;

  top.host = extType(top.givenQualifiers, refIdExtType(structSEU(), just(mangledName),
    s"edu:umn:cs:melt:exts:ableC:parallel:exts:lvars:${mangledName}"));
  top.mangledName = mangledName;
  top.isEqualTo = 
    \ other::ExtType ->
      case other of
      | lvarType(_, _, _, mn) -> mn == mangledName
      | _ -> false
      end;

  -- Override new and delete to actually do important things
  top.newProd = 
    just(\e::Exprs l::Location -> lvarNew(e, top, location=l));
  top.deleteProd = just(\e::Expr -> lvarDelete(e, top));
  -- TODO: exprInitProd, objectInitProd (it would be nice to support these so
  -- we don't have to use the new ...(...), but the implementation is not
  -- incomplete without them

  -- Override literally everything else to make it an error
  local errExpr :: (Expr ::= Location) =
    \loc::Location -> errorExpr([err(loc, "An lvar cannot be accessed except by a put (<-), get, or freeze")], location=loc);

  -- Should some of these not be included? i.e. should we check whether
  -- these operations are even defined on the inner type?
  top.ovrld:arraySubscriptProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:callProd = just(\e::Expr es::Exprs l::Location -> errExpr(l));
  top.ovrld:callMemberProd = just(\e::Expr b::Boolean n::Name es::Exprs l::Location -> errExpr(l));
  top.ovrld:memberProd = just(\e::Expr b::Boolean n::Name l::Location -> errExpr(l));
  top.ovrld:preIncProd = just(\e::Expr l::Location -> errExpr(l));
  top.ovrld:preDecProd = just(\e::Expr l::Location -> errExpr(l));
  top.ovrld:postIncProd = just(\e::Expr l::Location -> errExpr(l));
  top.ovrld:postDecProd = just(\e::Expr l::Location -> errExpr(l));
  top.ovrld:addressOfArraySubscriptProd = just(\e::Expr i::Expr l::Location -> errExpr(l));
  top.ovrld:addressOfCallProd = just(\e::Expr h::Exprs l::Location -> errExpr(l));
  top.ovrld:addressOfMemberProd = just(\e::Expr b::Boolean n::Name l::Location -> errExpr(l));
  top.ovrld:dereferenceProd = just(\e::Expr l::Location -> errExpr(l));
  top.ovrld:positiveProd = just(\e::Expr l::Location -> errExpr(l));
  top.ovrld:negativeProd = just(\e::Expr l::Location -> errExpr(l));
  top.ovrld:bitNegateProd = just(\e::Expr l::Location -> errExpr(l));
  top.ovrld:notProd = just(\e::Expr l::Location -> errExpr(l));
  
  -- We have to allow this so we can allow constructions using 'new'
  top.ovrld:lEqProd = just(\x::Expr r::Expr l::Location -> lvarLEq(x, r, 
                                  sys, mangledName, inner, location=l));
  
  top.ovrld:rEqProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:eqArraySubscriptProd = just(\e::Expr i::Expr x::Expr l::Location -> errExpr(l));
  top.ovrld:eqCallProd = just(\e::Expr a::Exprs x::Expr l::Location -> errExpr(l));
  top.ovrld:eqMemberProd = just(\e::Expr b::Boolean n::Name x::Expr l::Location -> errExpr(l));
  
  top.ovrld:lMulEqProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rMulEqProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:lDivEqProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rDivEqProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:lModEqProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rModEqProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:lAddEqProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rAddEqProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:lSubEqProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rSubEqProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:lLshEqProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rLshEqProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:lRshEqProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rRshEqProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:lAndEqProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rAndEqProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:lXorEqProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rXorEqProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:lOrEqProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rOrEqProd = just(\x::Expr r::Expr l::Location -> errExpr(l));

  top.ovrld:lAndProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rAndProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:lOrProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rOrProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  
  top.ovrld:lAndBitProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rAndBitProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:lOrBitProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rOrBitProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  
  top.ovrld:lXorProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rXorProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  
  top.ovrld:lLshBitProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rLshBitProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:lRshBitProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rRshBitProd = just(\x::Expr r::Expr l::Location -> errExpr(l));

  top.ovrld:lEqualsProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rEqualsProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:lNotEqualsProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rNotEqualsProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  
  top.ovrld:lLtProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rLtProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:lGtProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rGtProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:lLteProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rLteProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:lGteProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rGteProd = just(\x::Expr r::Expr l::Location -> errExpr(l));

  top.ovrld:lAddProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rAddProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:lSubProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rSubProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:lMulProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rMulProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:lDivProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rDivProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:lModProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
  top.ovrld:rModProd = just(\x::Expr r::Expr l::Location -> errExpr(l));
}

abstract production lvarLEq
top::Expr ::= l::Expr r::Expr sys::LockSystem mangledName::String inner::Type
{
  top.pp = ppConcat([l.pp, space(), text("="), space(), r.pp]);

  propagate controlStmtContext, env;

  forwards to
    case r of
    | newExpr(_, args) -> initializeLVar(l, args, sys, mangledName, inner, location=top.location)
    | _ -> errorExpr(
      [err(top.location, "An lvar cannot be accessed except by a put (<-), get, or freeze")],
      location=top.location)
    end;
}

abstract production lvarNew
top::Expr ::= e::Exprs lvarType::ExtType
{
  top.pp = ppConcat([text("new"), space(), lvarType.pp, parens(ppImplode(comma(), e.pps))]);
  forwards to
    errorExpr([err(top.location,
      "Construction of an lvar only allowed on the rhs of an assignment")],
      location=top.location);
}

abstract production initializeLVar
top::Expr ::= l::Expr args::Exprs sys::LockSystem mangledName::String inner::Type
{
  top.pp = text("/* lVar initialization */");

  propagate controlStmtContext, env;

  local lhs::Expr = exprAsType(l,
    extType(nilQualifier(),
      refIdExtType(structSEU(), just(mangledName),
        s"edu:umn:cs:melt:exts:ableC:parallel:exts:lvars:${mangledName}")),
    location=top.location);

  lhs.env = top.env;
  lhs.controlStmtContext = top.controlStmtContext;

  local localErrors :: [Message] =
    case args of
    | consExpr(_, nilExpr()) -> []
    | _ -> [err(top.location, "lVar should be created with a single argument")]
    end;

  local lub :: Expr =
    case args of
    | consExpr(l, _) -> l
    | _ -> error("Not encountered because of error handling")
    end;

  forwards to
    if null(localErrors)
    then
      ableC_Expr {
        ({
          $Expr{lhs}.value = inst Bottom<$directTypeExpr{inner}>();
          $Expr{lhs}.lub = $Expr{lub};
          $Expr{lhs}.frozen = 0;

          $Expr{sys.initializeLock(ableC_Expr{$Expr{lhs}.access}, nilExpr(), top.location)};
          $Expr{sys.initializeCondvar(ableC_Expr{$Expr{lhs}.wait},
            consExpr(
              explicitCastExpr(
                typeName(
                  extTypeExpr(nilQualifier(), lockType(sys)),
                  pointerTypeExpr(nilQualifier(),
                    baseTypeExpr())
                ),
                ableC_Expr{&($Expr{lhs}.access)}, 
                location=top.location
              ),
              nilExpr()
            ),
            top.location
          )};

          $Expr{l};
        })
      }
    else errorExpr(localErrors, location=top.location);
}

abstract production lvarDelete
top::Stmt ::= e::Expr varType::ExtType
{
  top.pp = ppConcat([text("delete"), space(), e.pp]);

  local sys::LockSystem =
    case varType of
    | lvarType(s, _, _, _) -> s
    | _ -> error("This function only called by being this type")
    end;

  sys.env = top.env;

  forwards to
    ableC_Stmt {
      {
        struct $name{varType.mangledName}* __obj =
          (struct $name{varType.mangledName}*) &$Expr{e};
        $Stmt{sys.lockDeleteProd.fromJust(ableC_Expr{&(__obj->access)})}
        $Stmt{sys.condvarDeleteProd.fromJust(ableC_Expr{&(__obj->wait)})}
      }
    };
}
