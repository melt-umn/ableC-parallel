grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel;

abstract production testParSystem 
top::ParallelSystem ::=
{
  top.parName = "testing";
  top.typeImpl = refIdExtType(structSEU(), "system_test", "edu:umn:cs:melt:exts:ableC:parallel:test");
  top.fSpawn = \e::Expr -> exprStmt(e);
  top.fFor = \n::Name e::Expr b::LoopBound u::LoopUpdate s::Stmt
                -> warnStmt([err(builtin, "Todo...")]);
}

abstract production testParallelQualifier
top::Qualifier ::= 
{
  top.pp = text("test");
  top.mangledName = "test";
  top.qualIsPositive = true;
  top.qualIsNegative = false;
  top.qualAppliesWithinRef = true;
  top.qualCompat = \qualToCompare::Qualifier ->
    case qualToCompare of testParallelQualifier() -> true | _ -> false end;
  top.qualIsHost = false;
  top.errors := [];

  top.parSystem = just(testParSystem());
}
