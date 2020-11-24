grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:testing;

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
  
  top.fSpawn = \e::Expr a::SpawnAnnotations -> exprStmt(e);
  top.fFor = \n::Name t::Type e::Expr b::LoopBound u::LoopUpdate s::Stmt a::ParallelAnnotations
                -> sequentialFor(n, t, e, b, u, s);

  top.newProd = nothing();
  top.deleteProd = nothing();
}

abstract production fakeLock
top::Stmt ::= locks::[Expr] val::Integer
{
  top.pp = text("fake_lock_operation");
  top.functionDefs := [];

  forwards to foldStmt(
    map(\ e::Expr -> 
      let t :: Type = 
        (decorate e with {env=top.env; returnType=nothing();}).typerep
      in exprStmt(
        eqExpr(
          memberExpr(
            explicitCastExpr(typeName(t.host.baseTypeExpr, t.host.typeModifierExpr),
              e, location=builtin), 
            case t of 
              | pointerType(_, _) -> true | _ -> false end,
            name("tmp", location=builtin), location=builtin), 
          mkIntConst(val, e.location),
          location=builtin
        )
      )
      end,
      locks
    )
  );
}

abstract production testLockSystem
top::LockSystem ::=
{
  top.parName = "testing";
  top.lockType = 
    (decorate 
      refIdExtType(structSEU(), just("system_test"), "edu:umn:cs:melt:exts:ableC:parallel:test")
    with {givenQualifiers=nilQualifier();}).host;
  
  top.acquireLocks = fakeLock(top.locks, 1);
  top.releaseLocks = fakeLock(top.locks, 0);

  top.condType =
    (decorate 
      refIdExtType(structSEU(), just("system_test"), "edu:umn:cs:melt:exts:ableC:parallel:test")
    with {givenQualifiers=nilQualifier();}).host;

  top.waitCV = nullStmt();
  top.signalCV = nullStmt();
  top.broadcastCV = nullStmt();

  top.lockNewProd = nothing();
  top.lockDeleteProd = nothing();
  top.condvarNewProd = nothing();
  top.condvarDeleteProd = nothing();
}

abstract production testSyncSystem
top::SyncSystem ::=
{
  top.parName = "testing";
  top.threadType = refIdExtType(structSEU(), just("system_test"), "edu:umn:cs:melt:exts:ableC:parallel:test");
  top.setThread = \e::Expr -> nullStmt();
  top.finishThread = \e::Expr -> nullStmt();
  top.syncThread = \e::[Expr] -> nullStmt();

  top.groupType = refIdExtType(structSEU(), just("system_test"), "edu:umn:cs:melt:exts:ableC:parallel:test");
  top.initGroup = mkIntConst(0, builtin);
  top.addGroup = \e::Expr -> nullStmt();
  top.finishGroup = \e::Expr -> nullStmt();
  top.syncGroup = \e::[Expr] -> nullStmt();
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
  top.lockSystem = just(testLockSystem());
  top.syncSystem = just(testSyncSystem());
}
