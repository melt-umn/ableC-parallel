grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:loop;

abstract production parallelFor
top::Stmt ::= init::Decl cond::MaybeExpr iter::Expr body::Stmt 
              annts::ParallelAnnotations
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
  local varType :: Type = init.parLoopType.fromJust;
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
    ++ body.loopVarErrs
    ++  if !annts.parallelBy.isJust
        then [err(builtin, "Parallel for-loop is missing annotation to specify which system to use")]
        else
          case systemType of
          | extType(_, parallelType(_)) -> []
          | _ -> [err(parallelBy.location, "Expression specifying the parallel system is not an appropriate type")]
          end;

  local propagateErrors :: [Message] = 
    init.errors ++ cond.errors ++ iter.errors ++ body.errors ++ annts.errors;

  top.errors := if null(propagateErrors) 
                then parLoopErrors 
                else propagateErrors;


  local parallelBy :: Expr = annts.parallelBy.fromJust;

  parallelBy.env = top.env;
  parallelBy.returnType = top.returnType;

  local systemType :: Type = parallelBy.typerep;
  local sys :: ParallelSystem =
    case systemType of
    | extType(_, parallelType(s)) -> s
    end;

  forwards to 
    if !null(top.errors)
    then warnStmt(top.errors)
    else sys.fFor(declName, varType, varInit, loopCond, loopUpdate, body);
}
