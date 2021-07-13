grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel;

inherited attribute lookupParName :: String;
synthesized attribute parNameIndex :: Integer;

nonterminal SystemNumbering with lookupParName, parNameIndex;

function indexOf
Integer ::= eq::(Boolean ::= a b) x::a lst::[b]
{
  return indexOfHelper(eq, x, lst, 0);
}

function indexOfHelper
Integer ::= eq::(Boolean ::= a b) x::a lst::[b] curPos::Integer
{
  return 
    if null(lst) then -1
    else if eq(x, head(lst)) then curPos
    else indexOfHelper(eq, x, tail(lst), curPos+1);
}

abstract production systemNumbering
top::SystemNumbering ::= 
{
  production attribute systems :: [ParallelSystem] with ++;
  systems := [placeHolderParSystem()];

  top.parNameIndex = indexOf(
    \nm::String sys::ParallelSystem -> nm == sys.parName,
    top.lookupParName,
    systems);
}

-- Used to make sure index 0 is assigned to the main thread's "system"
abstract production placeHolderParSystem
top::ParallelSystem ::=
{
  top.parName = "__main_thread";
  top.fSpawn = \e::Expr l::Location a::SpawnAnnotations 
    -> warnStmt([err(l, "Placeholder parallel system should never be used")]);
  top.fFor = \s::Stmt l::Location a::ParallelAnnotations 
    -> warnStmt([err(l, "Placeholder parallel system should never be used")]);
  top.newProd = nothing();
  top.deleteProd = nothing();
  top.transFunc = \f::ParallelFunctionDecl
    -> warnDecl([err(builtinLoc("ableC-parallel"), "Placeholder parallel system should never be used")]);
}
