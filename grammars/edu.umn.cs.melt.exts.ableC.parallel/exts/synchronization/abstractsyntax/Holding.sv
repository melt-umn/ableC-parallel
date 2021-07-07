grammar edu:umn:cs:melt:exts:ableC:parallel:exts:synchronization:abstractsyntax;

abstract production holdingStmt
top::Stmt ::= e::Expr nm::Name bd::Stmt
{
  top.pp = ppConcat([text("holding"), space(), parens(e.pp), space(),
    text("as"), space(), nm.pp, space(), bd.pp]);

  top.functionDefs := bd.functionDefs;
  top.labelDefs := [];

  -- TODO: We need e to be an l-value
  local localErrors :: [Message] = e.errors ++
    case e.typerep of
    | extType(_, synchronizedType(_, _, _, _, _)) -> []
    | _ -> [err(e.location, "Expression must be a 'synchronized' object")]
    end;

  local sys :: LockSystem =
    case e.typerep of
    | extType(_, synchronizedType(s, _, _, _, _)) -> s
    | _ -> error("Check errors attribute before checking the forward tree")
    end;
  local mangledName :: String =
    case e.typerep of
    | extType(_, synchronizedType(_, _, _, _, mn)) -> mn
    | _ -> error("Check errors attribute before checking the forward tree")
    end;

  -- For now, we prevent these control-flow problems (we could allow all of
  -- these, with appropriate code insertion to handle this)
  bd.controlStmtContext = initialControlStmtContext;
  bd.env = addEnv(
    valueDef(nm.name, 
      declaratorValueItem(
        decorate 
          declarator(
            nm,
            baseTypeExpr(),
            nilAttribute(),
            nothingInitializer()
          )
        with {
          env=top.env;
          controlStmtContext = initialControlStmtContext;  
          baseType=extType(nilQualifier(), 
                case e.typerep of
                | extType(_, eT) ->
                  case eT of
                  | synchronizedType(sys, inner, sync, pp, mn) ->
                    case sync of
                    | synchronizationDesc([], _) 
                        -> heldType(inner, pointerType(nilQualifier(), eT.host), 
                            accessValue(_, mn), true,
                            error("unsyncd held shouldn't access actions"),
                            sys, nm, mn, [])
                    | synchronizationDesc(conds, s) 
                        -> heldType(inner, pointerType(nilQualifier(), eT.host),
                            accessValue(_, mn), false,
                            s.actions, sys, nm, mn, conds)
                    end
                  | _ -> error("errors attribute should be accessed before the forward tree")
                  end
                | _ -> error("errors attribute should be accessed before the forward tree")
                end
              );
          typeModifierIn=baseTypeExpr();
          givenStorageClasses=nilStorageClass();
          givenAttributes=nilAttribute();
          isTopLevel=false;
          isTypedef=false;
        }
      )) :: [],
    openScopeEnv(top.env));

  sys.env = addEnv(
    valueDef(nm.name, 
      declaratorValueItem(
        decorate 
          declarator(
            nm,
            pointerTypeExpr(nilQualifier(), baseTypeExpr()),
            nilAttribute(),
            nothingInitializer()
          )
        with {
          env=top.env;
          controlStmtContext = initialControlStmtContext;  
          baseType=extType(nilQualifier(), refIdExtType(structSEU(),
            just(mangledName),
            s"edu:umn:cs:melt:exts:ableC:parallel:exts:synchronization:${mangledName}"));
          typeModifierIn=baseTypeExpr();
          givenStorageClasses=nilStorageClass();
          givenAttributes=nilAttribute();
          isTopLevel=false;
          isTypedef=false;
        }
      )) :: [],
    openScopeEnv(top.env));
  sys.locks = [ableC_Expr{&($Name{nm}->lck)}];
  
  forwards to
    if !null(localErrors)
    then warnStmt(localErrors)
    else ableC_Stmt {
    {
      struct $name{mangledName}* $Name{nm} = (struct $name{mangledName}*) &$Expr{e};
      $Stmt{sys.acquireLocks}

      {
        $Stmt{decStmt(bd)}
      }

      $Stmt{sys.releaseLocks}
    } };
}
