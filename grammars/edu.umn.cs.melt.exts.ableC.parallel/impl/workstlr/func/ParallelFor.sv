grammar edu:umn:cs:melt:exts:ableC:parallel:impl:workstlr:func;

aspect production parallelFor
top::Stmt ::= init::Decl cond::MaybeExpr iter::Expr body::Stmt
              annts::ParallelAnnotations
{
  -- A Workstlr for-loop does not have a by ...; annotation and also shouldn't have
  -- any other annotations on it. We translate it to a for-loop containing a
  -- spawn
  
  local anyAnnotations :: Boolean =
    case annts of
    | nilParallelAnnotations() -> false
    | _ -> true
    end;

  top.workstlrParForConverted =
    if anyAnnotations
    then top
    else
      case decorate cleanLoopBody(body, top.env)
            with {env=top.env; controlStmtContext=initialControlStmtContext;}
      of
      | exprStmt(ex) ->
        forDeclStmt(
          init, cond, justExpr(iter),
          spawnTask(ex, nilSpawnAnnotations())
        )
      | _ -> warnStmt([err(iter.location, "Workstlr parallel-for loop must contain only a single expression")])
      end;
}

function cleanLoopBody
Stmt ::= s::Stmt env::Decorated Env
{
  s.controlStmtContext = initialControlStmtContext;
  s.env = env;

  return
    case s of
    | exprStmt(e) -> exprStmt(cleanLoopBodyExpr(e, env))
    | ableC_Stmt { { $Stmt{i} } } -> cleanLoopBody(i, env)
    | _ -> s
    end;
}

function cleanLoopBodyExpr
Expr ::= e::Expr env::Decorated Env
{
  e.controlStmtContext = initialControlStmtContext;
  e.env = env;

  return
    case e of
    | ableC_Expr { ( $Expr{i} ) } -> cleanLoopBodyExpr(i, env)
    | _ -> e
    end;
}
