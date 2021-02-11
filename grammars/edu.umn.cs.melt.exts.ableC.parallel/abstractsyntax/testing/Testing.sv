grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:testing;

abstract production testParSystem 
top::ParallelSystem ::=
{
  top.parName = "testing";
  
  top.fSpawn = \e::Expr l::Location a::SpawnAnnotations -> exprStmt(e);
  top.fFor = \s::Stmt l::Location a::ParallelAnnotations -> s;

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
        (decorate e with {env=top.env; returnType=nothing(); breakValid=false; continueValid=false; }).typerep
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

  top.initializeLock = error("testing lock cannot be initialize");
  top.lockDeleteProd = nothing();
  top.initializeCondvar = error("testing condvar cannot be initialize");
  top.condvarDeleteProd = nothing();
}

abstract production testSyncSystem
top::SyncSystem ::=
{
  top.parName = "testing";
  top.threadType =
    (decorate
      refIdExtType(structSEU(), just("system_test"), "edu:umn:cs:melt:exts:ableC:parallel:test")
    with {givenQualifiers=nilQualifier();}).host;

  top.threadBefrOps = nullStmt();
  top.threadThrdOps = nullStmt();
  top.threadPostOps = nullStmt();
  top.syncThreads = nullStmt();

  top.groupType = 
    (decorate
      refIdExtType(structSEU(), just("system_test"), "edu:umn:cs:melt:exts:ableC:parallel:test")
    with {givenQualifiers=nilQualifier();}).host;

  top.groupBefrOps = nullStmt();
  top.groupThrdOps = nullStmt();
  top.groupPostOps = nullStmt();
  top.syncGroups = nullStmt();

  top.initializeThread = error("testing thread cannot be initialized");
  top.threadDeleteProd = nothing();
  top.initializeGroup = error("testing group cannot be initialized");
  top.groupDeleteProd = nothing();
}

abstract production testParallelQualifier
top::Qualifier ::= 
{
  top.pp = text("testing");
  top.mangledName = "testing";
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
