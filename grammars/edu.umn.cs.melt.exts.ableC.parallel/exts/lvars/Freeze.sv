grammar edu:umn:cs:melt:exts:ableC:parallel:exts:lvars;

abstract production lvarFreeze
top::Expr ::= lvar::Expr
{
  top.pp = ppConcat([text("freeze"), space(), lvar.pp]);

  propagate controlStmtContext, env;

  local localErrors :: [Message] =
    case lvar.typerep of
    | extType(_, lvarType(_, _, _, _)) -> []
    | _ -> [err(top.location, "Freeze operation only supported for lvars")]
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
  
  forwards to
    if !null(lvar.errors)
    then errorExpr(lvar.errors, location=lvar.location)
    else if !null(localErrors)
    then errorExpr(localErrors, location=top.location)
    else ableC_Expr {
        ({
          $Decl{ableC_Decl{inst Value<$directTypeExpr{inner}> _res;}}
          struct $name{mangledName}* _lvar = (struct $name{mangledName}*)&$Expr{lvar};

          $Stmt{sys.acquireLocks}
          
          _lvar->frozen = 1;
          _res = _lvar->value;
          
          $Stmt{sys.releaseLocks}
          _res;
        })
      };
}
