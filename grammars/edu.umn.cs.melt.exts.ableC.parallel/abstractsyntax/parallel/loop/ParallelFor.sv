grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel:loop;

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

  local publicVars :: [Name]  = annts.publics;
  local privateVars :: [Name] = annts.privates;
  local globalVars :: [Name]  = annts.globals;

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
    ++  if !annts.bySystem.isJust
        then [err(builtin, "Parallel for-loop is missing annotation to specify which system to use")]
        else
          case systemType of
          | extType(_, parallelType(_)) -> []
          | _ -> [err(bySystem.location, "Expression specifying the parallel system is not an appropriate type")]
          end
    ++ (if !null(intersectBy(nameEq, intersectBy(nameEq, globalVars, privateVars), publicVars))
        then [err(builtin, "Some variables listed in multiple public / private / global annotations")]
        else []);

  local propagateErrors :: [Message] = 
    init.errors ++ cond.errors ++ iter.errors ++ body.errors ++ annts.errors;

  top.errors := if null(propagateErrors) 
                then parLoopErrors 
                else propagateErrors;


  local bySystem :: Expr = annts.bySystem.fromJust;

  bySystem.env = top.env;
  bySystem.returnType = top.returnType;

  local systemType :: Type = bySystem.typerep;
  local sys :: ParallelSystem =
    case systemType of
    | extType(_, parallelType(s)) -> s
    end;

  forwards to 
    if !null(top.errors)
    then warnStmt(top.errors)
    else sys.fFor(declName, varType, varInit, loopCond, loopUpdate, body, annts);
}
