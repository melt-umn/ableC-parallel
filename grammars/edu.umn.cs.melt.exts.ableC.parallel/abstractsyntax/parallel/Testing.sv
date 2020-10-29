grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel;

abstract production sequentialFor
top::Stmt ::= n::Name t::Type init::Expr bound::LoopBound update::LoopUpdate 
              body::Stmt
{
  -- TODO: Location
  local varDecl :: Decl =
    variableDecls(
      nilStorageClass(),
      nilAttribute(),
      t.baseTypeExpr,
      consDeclarator(
        declarator(
          n,
          baseTypeExpr(),
          nilAttribute(),
          justInitializer(exprInitializer(init, location=builtin))
        ),
        nilDeclarator()));

  local cond :: MaybeExpr =
    justExpr(
      case bound of
      | lessThan(val) ->
          ltExpr(
            declRefExpr(n, location=builtin),
            val, location=builtin)
      | lessThanOrEqual(val) ->
          lteExpr(
            declRefExpr(n, location=builtin),
            val, location=builtin)
      | greaterThan(val) ->
          gtExpr(
            declRefExpr(n, location=builtin),
            val, location=builtin)
      | greaterThanOrEqual(val) ->
          gteExpr(
            declRefExpr(n, location=builtin),
            val, location=builtin)
      | notEqual(val) ->
          notEqualsExpr(
            declRefExpr(n, location=builtin),
            val, location=builtin)
      end);

  local iter :: MaybeExpr = 
    justExpr(
      case update of
      | add(amt) ->
          addEqExpr(
            declRefExpr(n, location=builtin),
            amt, location=builtin)
      | subtract(amt) ->
          subEqExpr(
            declRefExpr(n, location=builtin),
            amt, location=builtin)
      end);

  forwards to forDeclStmt(varDecl, cond, iter, body);
}

abstract production testParSystem 
top::ParallelSystem ::=
{
  top.parName = "testing";
  top.typeImpl = refIdExtType(structSEU(), "system_test", "edu:umn:cs:melt:exts:ableC:parallel:test");
  top.fSpawn = \e::Expr -> exprStmt(e);
  top.fFor = \n::Name t::Type e::Expr b::LoopBound u::LoopUpdate s::Stmt
                -> sequentialFor(n, t, e, b, u, s);
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
