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

  local loopS :: Stmt = ableC_Stmt {
      for($Decl{init} $Expr{cond.justTheExpr.fromJust}; $Expr{iter}) $Stmt{body}
    };
  loopS.returnType = nothing();
  -- Breaking from a parallel loop is not allowed because we're running
  -- iterations in parallel. A continue is fine (we require that the
  -- impleemntation use a loop, so this behaves as expected)
  loopS.breakValid = false;
  loopS.continueValid = true;
  loopS.env = top.env;

  local normalizedS :: Stmt = loopS.normalizeLoops;
  normalizedS.returnType = nothing();
  normalizedS.breakValid = false;
  normalizedS.continueValid = true;
  normalizedS.env = loopS.env;

  local normalizedProperly :: Boolean =
    case normalizedS of
    | ableC_Stmt { for($BaseTypeExpr{t} $Name{i1} = host::(0); host::$Name{i2} host::< $Expr{n}; host::$Name{i3} host::++) $Stmt{b}
      } when i1.name == i2.name && i1.name == i3.name && t.typerep.isIntegerType -> true
    | _ -> false
    end;

  local bySystem :: Expr = annts.bySystem.fromJust;

  bySystem.env = top.env;
  bySystem.returnType = top.returnType;
  bySystem.breakValid = top.breakValid;
  bySystem.continueValid = top.continueValid;

  local systemType :: Type = bySystem.typerep;
  local sys :: ParallelSystem =
    case systemType of
    | extType(_, parallelType(s)) -> s
    end;

  forwards to 
    if !cond.isJust
    then warnStmt([err(iter.location, "Parallel for-loop must have a condition")])
    else if !null(loopS.errors)
    then warnStmt(loopS.errors)
    else if !null(annts.errors)
    then warnStmt(annts.errors)
    else if !null(normalizedS.errors)
    then warnStmt(normalizedS.errors)
    else if !normalizedProperly
    then warnStmt([err(iter.location, "Parallel for-loop could not be normalized correctly")])
    else sys.fFor(normalizedS, iter.location, annts); -- TODO: Location
}
