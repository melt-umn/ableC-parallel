grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel:spawn;

abstract production spawnTask
top::Stmt ::= expr::Expr annts::SpawnAnnotations
{
  expr.env = top.env;

  propagate controlStmtContext;

  annts.env = top.env;

  top.pp = ppConcat([text("spawn"), space(), expr.pp, semi()]);
  top.functionDefs := [];
  top.labelDefs := [];

  local privateVars :: [Name] = nub(annts.privates);
  local publicVars  :: [Name] = nub(annts.publics);
  local globalVars  :: [Name] = nub(annts.globals);

  -- TODO: Location
  local localErrors :: [Message] =
    expr.errors ++ annts.errors 
    ++ (if !annts.bySystem.isJust
       then [err(expr.location, "Spawn is missing annotation to specify which system to use")]
       else 
         case systemType of
         | extType(_, parallelType(_)) -> []
         | _ -> [err(spawnBy.location, "Expression specifying the spawn system is not an appropriate type")]
         end)
    ++ (if !null(intersect(intersect(globalVars, privateVars), publicVars))
        then [err(expr.location, "Some variables listed in multiple public / private / global annotations")]
        else []);

  local spawnBy :: Expr = annts.bySystem.fromJust;

  spawnBy.env = top.env;
  -- Because we exectue in parallel, don't allow anything that is based on
  -- executing in this location (so no return, break, or continue based on
  -- the current location of code)
  spawnBy.controlStmtContext = initialControlStmtContext;

  local systemType :: Type = spawnBy.typerep;
  local sys :: ParallelSystem = 
    case systemType of
    | extType(_, parallelType(s)) -> s
    | _ -> error("Bad type should be caught by errors attribute")
    end;

  forwards to
    if !null(localErrors)
    then warnStmt(localErrors)
    else sys.fSpawn(expr, expr.location, annts);
}
