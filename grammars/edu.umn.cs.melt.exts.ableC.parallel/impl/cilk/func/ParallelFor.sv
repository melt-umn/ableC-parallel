grammar edu:umn:cs:melt:exts:ableC:parallel:impl:cilk:func;

aspect production parallelFor
top::Stmt ::= init::Decl cond::MaybeExpr iter::Expr body::Stmt
              annts::ParallelAnnotations
{
  -- A cilk for-loop does not have a by ...; annotation and also shouldn't have
  -- any other annotations on it
  
  local fwrd :: Stmt = new(top.forward);
  fwrd.controlStmtContext = top.controlStmtContext;
  fwrd.env = top.env;
  
  local anyAnnotations :: Boolean =
    case annts of
    | nilParallelAnnotations() -> false
    | _ -> true
    end;

  local form :: Maybe<(Expr, Exprs)> =
    case body of
    | ableC_Stmt { { $Expr{directCallExpr(f, args)}; } } ->
          just((ableC_Expr{$name{s"_cilk_${f.name}"}}, new(args)))
    | _ -> nothing()
    end;

  top.cilkVersion =
    if annts.bySystem.isJust
    then fwrd
    else if anyAnnotations
    then warnStmt([err(iter.location, "Annotations not currently supported on cilk-syle parallel loops.")])
    else if !form.isJust
    then warnStmt([err(iter.location, "Body of cilk-style parallel for-loop should be a function invocation")])
    else cilkForDeclStmt(init, cond, justExpr(iter),
            cilkForBody(form.fromJust.fst, form.fromJust.snd));
}
