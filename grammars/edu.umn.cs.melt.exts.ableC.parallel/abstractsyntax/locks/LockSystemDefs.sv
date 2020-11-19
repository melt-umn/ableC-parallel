grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:locks;

synthesized attribute lockType :: Type;
inherited attribute locks :: [Expr];
synthesized attribute acquireLocks :: Stmt;
synthesized attribute releaseLocks :: Stmt;

synthesized attribute condType :: Type;
inherited attribute condvar :: Expr;
synthesized attribute waitCV :: Stmt;
synthesized attribute signalCV :: Stmt;
synthesized attribute broadcastCV :: Stmt;

closed nonterminal LockSystem with parName, env,
                                    lockType, locks, acquireLocks, releaseLocks,
                                    condType, condvar, waitCV, signalCV, broadcastCV;

flowtype LockSystem = decorate{env},
                      acquireLocks{env, locks}, releaseLocks{env, locks},
                      waitCV{env, condvar}, signalCV{env, condvar}, broadcastCV{env, condvar},
                      lockType{decorate}, condType{decorate};

synthesized attribute lockSystem :: Maybe<LockSystem> occurs on Qualifier;

aspect default production 
top::Qualifier ::=
{
  top.lockSystem = nothing();
}

