grammar edu:umn:cs:melt:exts:ableC:parallel:exts:lvars;

abstract production lvarPut
top::Expr ::= lhs::Expr rhs::Expr
{
  top.pp = ppConcat([lhs.pp, space(), text("<-"), space(), rhs.pp]);

  propagate controlStmtContext, env;

  local localErrors :: [Message] =
    lhs.errors ++ rhs.errors ++
    case lhs.typerep of
    | extType(_, lvarType(_, _, _, _)) ->
      (if typeAssignableTo(inner, rhs.typerep)
      then []
      else [err(top.location, "Incompatible type in rhs of put, expected " ++ showType(inner) ++ " but found " ++ showType(rhs.typerep))])
      ++
      if lhs.isLValue then []
      else [err(lhs.location, "lvalue required as left operation of put")]
    | _ -> [err(top.location, "Put (<-) operation only supported for lvars")]
    end;
  
  local sys::LockSystem =
    case lhs.typerep of
    | extType(_, lvarType(s, _, _, _)) -> s
    | _ -> error("Not reached, errors reported via errors attribute")
    end; 
  local inner::Type =
    case lhs.typerep of
    | extType(_, lvarType(_, i, _, _)) -> i
    | _ -> error("Not reached, errors reported via errors attribute")
    end;
  local mangledName::String =
    case lhs.typerep of
    | extType(_, lvarType(_, _, _, n)) -> n
    | _ -> error("Not reached, errors reported via errors attribute")
    end;

  sys.env = top.env;
  sys.locks = [ableC_Expr{&(_lhs->access)}];
  sys.condvar = ableC_Expr{&(_lhs->wait)};

  forwards to
    if null(localErrors)
    then ableC_Expr {
        ({
          $directTypeExpr{inner} _rhs = $Expr{rhs};
          struct $name{mangledName}* _lhs = (struct $name{mangledName}*)&$Expr{lhs};
         
          $Stmt{sys.acquireLocks}
          
          if (_lhs->frozen) {
            fprintf(stderr, "Put not allowed on a frozen lvar\n");
            exit(1);
          }

          _lhs->lub(&(_lhs->value), _rhs);

          $Stmt{sys.broadcastCV}
          $Stmt{sys.releaseLocks}

          _rhs;
        })
      }
    else errorExpr(localErrors, location=top.location);
}
