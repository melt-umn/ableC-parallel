grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:locks;

abstract production genericLockOperation
top::Stmt ::= locks::Exprs sysFunc::((Stmt ::= [Expr]) ::= LockSystem)
{
  locks.env = top.env;

  top.pp = ppConcat([text("acquire"), space(), 
    ppImplode(cat(comma(), space()), locks.pps)]);
  top.functionDefs := [];

  -- TODO: location
  local localErrors :: [Message] = locks.errors
    ++ flatMap(
        \tp::Type -> 
          case tp of
          | extType(_, lockType(_)) -> []
          | _ -> [err(builtin, "Acquire can only be used on objects of type lock")]
          end,
        locks.typereps);

  local lockSystems :: [LockSystem] =
    nubBy(\ s1::LockSystem s2::LockSystem -> s1.parName == s2.parName,
      map(\ ty::Type -> case ty of | extType(_, lockType(s)) -> s end,
        locks.typereps));

  local acquireStmts :: [Stmt] =
    map(\ sys::LockSystem ->
      sysFunc(sys) (
        filter(\ex::Expr -> 
          case (decorate ex with {env=top.env; returnType=top.returnType;}).typerep of 
            | extType(_, lockType(s)) -> s.parName == sys.parName end,
          locks.exprList)
        ),
      lockSystems);

  forwards to
    if !null(localErrors)
    then warnStmt(localErrors)
    else foldStmt(acquireStmts);
}

abstract production acquireLock
top::Stmt ::= locks::Exprs
{
  forwards to genericLockOperation(locks, \sys::LockSystem -> sys.fAcquire);
}

abstract production releaseLock
top::Stmt ::= locks::Exprs
{
  forwards to genericLockOperation(locks, \sys::LockSystem -> sys.fRelease);
}
