grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax;

abstract production parallelFor
top::Stmt ::= init::Decl cond::MaybeExpr iter::Expr body::Stmt 
              annts::[ParallelAnnotation]
{
  init.env = openScopeEnv(top.env);
  cond.env = addEnv(init.defs, init.env);
  iter.env = addEnv(cond.defs, cond.env);
  body.env = addEnv(iter.defs, iter.env);
  init.isTopLevel = false;

  local declName :: Name =
    case init of
    | variableDecls(_, _, _,
        consDeclarator(
          declarator(nm, _, _, _),
          nilDeclarator())) -> nm
    end;
  local varInit :: Expr =
    case init of
    | variableDecls(_, _, _,
        consDeclarator(
          declarator(_, _, _, justInitializer(exprInitializer(e))),
          nilDeclarator())) -> e
    end;

  -- The locations on the errors are weird (because Decl don't have location)
  -- should probably find a better location to use if possible
  local localErrors :: [Message] = 
    case init of
    | variableDecls(_, _, ty, dcls) -> 
        if ty.typerep.isIntegerType
        then 
          case dcls of
          | consDeclarator(dcl, nilDeclarator()) -> 
            case dcl of
            | declarator(_, tm, _, intz) -> 
              case tm of
              | baseTypeExpr() -> 
                case intz of
                | justInitializer(_) -> []
                | nothingInitializer() -> 
                  [err(iter.location, "Parallel for-loops must initializer their loop-variable")]
                end
              | _ -> [err(iter.location, "Parallel for-loops must declare a loop-variable of integer type")]
              end
            | _ -> [err(iter.location, "Parallel for-loop variable declaration is incorrect")]
            end
          | _ -> [err(iter.location, "Parallel for-loops must declare only a single loop-variable")]
          end
        else [err(iter.location, "Parallel for-loops must declare a loop-variable of integer type")]
    | _ -> [err(iter.location, "Parallel for-loops must declare a single loop-variable of an integer type")]
    end;

  top.errors := localErrors ++ init.errors ++ cond.errors ++ iter.errors
                ++ body.errors;

  forwards to forDeclStmt(init, cond, justExpr(iter), body);
}

closed nonterminal ParallelAnnotation;

abstract production fakeParallelAnnotation
top::ParallelAnnotation ::= expr::Expr
{
}
