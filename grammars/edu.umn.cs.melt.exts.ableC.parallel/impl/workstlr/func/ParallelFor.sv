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
      case decorate cleanStmt(body, top.env)
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
