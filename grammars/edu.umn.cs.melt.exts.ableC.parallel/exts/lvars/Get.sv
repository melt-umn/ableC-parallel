grammar edu:umn:cs:melt:exts:ableC:parallel:exts:lvars;

abstract production lvarGet
top::Expr ::= lvar::Expr func::Expr
{
  top.pp = ppConcat([text("get"), space(), lvar.pp, space(), text("at"), space(), func.pp]);

  propagate controlStmtContext, env;

  -- TODO: typecheck func
  local localErrors :: [Message] =
    case lvar.typerep of
    | extType(_, lvarType(_, _, _, _)) -> []
    | _ -> [err(top.location, "Get operation only supported for lvars")]
    end;
  
  local sys::LockSystem =
    case lvar.typerep of
    | extType(_, lvarType(s, _, _, _)) -> s
    | _ -> error("Not reached, errors reported via errors attribute")
    end; 
  local inner::Type =
    case lvar.typerep of
    | extType(_, lvarType(_, i, _, _)) -> i
    | _ -> error("Not reached, errors reported via errors attribute")
    end;
  local mangledName::String =
    case lvar.typerep of
    | extType(_, lvarType(_, _, _, n)) -> n
    | _ -> error("Not reached, errors reported via errors attribute")
    end;

  sys.env = top.env;
  sys.locks = [ableC_Expr{&(_lvar->access)}];
  sys.condvar = ableC_Expr{&(_lvar->wait)};

  forwards to
    if !null(lvar.errors ++ func.errors)
    then errorExpr(lvar.errors ++ func.errors, location=top.location)
    else if !null(localErrors)
    then errorExpr(localErrors, location=top.location)
    else ableC_Expr {
        ({
          $Decl{ableC_Decl{inst Maybe<inst Value<$directTypeExpr{inner}>> _res;}}
          _res = inst Nothing<inst Value<$directTypeExpr{inner}>>();

          struct $name{mangledName}* _lvar = (struct $name{mangledName}*)&$Expr{lvar};
          $Decl{ableC_Decl{inst Maybe<inst Value<$directTypeExpr{inner}>> (*atFunc)(inst Value<$directTypeExpr{inner}>);}}
          atFunc = $Expr{func};

          $Stmt{sys.acquireLocks}
          
          while (inst isNothing<inst Value<$directTypeExpr{inner}>>(_res)) {
            _res = atFunc(_lvar->value);
            if (inst isNothing<inst Value<$directTypeExpr{inner}>>(_res)) {
              $Stmt{sys.waitCV}
            }
          }
          
          $Stmt{sys.releaseLocks}
          inst fromJust<inst Value<$directTypeExpr{inner}>>(_res);
        })
      };
}
