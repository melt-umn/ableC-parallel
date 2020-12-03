grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:sync;

synthesized attribute threadType :: Type;
synthesized attribute groupType :: Type;

inherited attribute threads :: [Expr]; -- List of threads for sync or ops
inherited attribute groups :: [Expr];  -- List of groups for sync or ops

synthesized attribute threadBefrOps :: Stmt; -- To be done synchronously before the thread
synthesized attribute threadThrdOps :: Stmt; -- To be done before work, in the thread (once TCB setup)
synthesized attribute threadPostOps :: Stmt; -- To execute once the thread is complete

synthesized attribute groupBefrOps :: Stmt; -- To be done synchrnously, before the thread
synthesized attribute groupThrdOps :: Stmt; -- To be done before work, in the thread (once TCB setup)
synthesized attribute groupPostOps :: Stmt; -- To be executed once the thread is complete

synthesized attribute syncThreads :: Stmt; -- Synchronize on threads
synthesized attribute syncGroups :: Stmt;  -- Synchronize on groups

synthesized attribute threadNewProd :: Maybe<(Expr ::= Exprs Location)>;
synthesized attribute threadDeleteProd :: Maybe<(Stmt ::= Expr)>;
synthesized attribute groupNewProd :: Maybe<(Expr ::= Exprs Location)>;
synthesized attribute groupDeleteProd :: Maybe<(Stmt ::= Expr)>;

closed nonterminal SyncSystem with parName, env,
                        threadType, groupType, threadNewProd, threadDeleteProd,
                        groupNewProd, groupDeleteProd, threads, groups,
                        threadBefrOps, threadThrdOps, threadPostOps,
                        groupBefrOps, groupThrdOps, groupPostOps,
                        syncThreads, syncGroups;

flowtype SyncSystem = decorate{env},
                      threadType{decorate}, groupType{decorate},
                      threadBefrOps{env, threads}, threadThrdOps{env, threads},
                      threadPostOps{env, threads}, syncThreads{env, threads},
                      groupBefrOps{env, groups}, groupThrdOps{env, groups},
                      groupPostOps{env, groups}, syncGroups{env, groups};

synthesized attribute syncSystem ::Maybe<SyncSystem> occurs on Qualifier;

aspect default production
top::Qualifier ::=
{
  top.syncSystem = nothing();
}
