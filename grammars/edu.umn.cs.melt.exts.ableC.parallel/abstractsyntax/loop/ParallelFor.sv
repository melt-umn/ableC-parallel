grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:loop;

abstract production parallelFor
top::Stmt ::= init::Decl cond::MaybeExpr iter::Expr body::Stmt 
              annts::[ParallelAnnotation]
{
  top.pp = ppConcat([text("parallel for"), space(), 
              parens(ppConcat([init.pp, space(), 
                              cond.pp, semi(), space(), 
                              iter.pp])),
                    line(), braces(nestlines(2, body.pp))]);
  top.functionDefs := body.functionDefs;

  init.env = openScopeEnv(top.env);
  cond.env = addEnv(init.defs, init.env);
  iter.env = addEnv(cond.defs, cond.env);
  body.env = addEnv(iter.defs, iter.env);
  init.isTopLevel = false;

  local declName :: Name = init.parLoopVar.fromJust;
  local varInit :: Expr = init.parLoopInit.fromJust;

  condExp.parLoopVarName = declName;
  iter.parLoopVarName = declName;
  body.parLoopVarName = declName;

  local condExp :: Expr = cond.justTheExpr.fromJust;
  condExp.env = cond.env;
  condExp.returnType = cond.returnType;

  local loopCond :: LoopBound = condExp.parLoopBound.fromJust;
  local loopUpdate :: LoopUpdate = iter.parLoopUpdate.fromJust;

  -- TODO: Find a better location
  local parLoopErrors :: [Message] =
    init.parLoopVarErrs ++ 
    (if init.parLoopVar.isJust
    then 
      (if cond.isJust
      then condExp.parLoopBoundErrs
      else [err(builtin, "Parallel for-loop must have a loop condition")])
      ++
      iter.parLoopUpdateErrs
    else [])
    ++ body.loopVarErrs;

  local propagateErrors :: [Message] = 
    init.errors ++ cond.errors ++ iter.errors ++ body.errors;

  top.errors := if null(propagateErrors) 
                then parLoopErrors 
                else propagateErrors;

  local modCond :: MaybeExpr =
    justExpr(
      case loopCond of
      | lessThan(bound) -> 
          ltExpr(
            declRefExpr(declName, location=builtin), 
            bound, location=builtin)
      | lessThanOrEqual(bound) -> 
          lteExpr(
            declRefExpr(declName, location=builtin), 
            bound, location=builtin)
      | greaterThan(bound) -> 
          gtExpr(
            declRefExpr(declName, location=builtin), 
            bound, location=builtin)
      | greaterThanOrEqual(bound) -> 
          gteExpr(
            declRefExpr(declName, location=builtin), 
            bound, location=builtin)
      | notEqual(bound) -> 
          notEqualsExpr(
            declRefExpr(declName, location=builtin), 
            bound, location=builtin)
      end);

  local modIter :: MaybeExpr =
    justExpr(
      case loopUpdate of
      | add(amt) ->
          addEqExpr(
            declRefExpr(declName, location=builtin),
            amt, location=builtin)
      | subtract(amt) ->
          subEqExpr(
            declRefExpr(declName, location=builtin),
            amt, location=builtin)
      end);

  forwards to 
    if !null(top.errors)
    then warnStmt(top.errors)
    else forDeclStmt(init, modCond, modIter, body);
  --forwards to forDeclStmt(init, cond, justExpr(iter), body);
}

closed nonterminal ParallelAnnotation;

abstract production fakeParallelAnnotation
top::ParallelAnnotation ::= expr::Expr
{
}
