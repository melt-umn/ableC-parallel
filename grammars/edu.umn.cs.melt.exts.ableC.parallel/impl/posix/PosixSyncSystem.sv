grammar edu:umn:cs:melt:exts:ableC:parallel:impl:posix;

abstract production posixSyncSystem
top::SyncSystem ::=
{
  top.parName = "posix";

  top.threadType =
    (decorate
      refIdExtType(structSEU(), just("__posix_sync"),
        "edu:umn:cs:melt:exts:ableC:parallel:impl:posix:sync")
    with {givenQualifiers=nilQualifier();}).host;

  top.groupType =
    (decorate
      refIdExtType(structSEU(), just("__posix_sync"),
        "edu:umn:cs:melt:exts:ableC:parallel:impl:posix:sync")
    with {givenQualifiers=nilQualifier();}).host;

  top.threadBefrOps = foldStmt(
    map(\t::Expr -> ableC_Stmt {
        {
          struct __posix_sync* _tmp = (struct __posix_sync*)
            $Expr{getReference(decorate t with {env=top.env;
                          controlStmtContext=initialControlStmtContext;})};
          checked_pthread_mutex_lock(&(_tmp->lk));
          if (__builtin_expect(_tmp->work != -1 || _tmp->waiting != 0, 0)) {
            fprintf(stderr, $stringLiteralExpr{s"Attempted to use an in-use thread object (${t.location.unparse})\n"});
            exit(-1);
          }
          _tmp->work = 1;
          checked_pthread_mutex_unlock(&(_tmp->lk));
        }
      },
      top.threads)
    );
  top.threadThrdOps = nullStmt();
  top.threadPostOps = foldStmt(
    map(\t::Expr -> ableC_Stmt {
        {
          struct __posix_sync* _tmp = (struct __posix_sync*)
            $Expr{getReference(decorate t with {env=top.env;
                          controlStmtContext=initialControlStmtContext;})};
          checked_pthread_mutex_lock(&(_tmp->lk));
          _tmp->work = 0;
          checked_pthread_cond_broadcast(&(_tmp->cv));
          checked_pthread_mutex_unlock(&(_tmp->lk));
        }
      },
      top.threads)
    );

  top.groupBefrOps = foldStmt(
    map(\g::Expr -> ableC_Stmt {
        {
          struct __posix_sync* _tmp = (struct __posix_sync*)
            $Expr{getReference(decorate g with {env=top.env;
                          controlStmtContext=initialControlStmtContext;})};
          checked_pthread_mutex_lock(&(_tmp->lk));
          // TODO: We would like some check to avoid adding threads to a group being waited on if there's a possible race condition (this would involve knowing if the current thread is in the group)
          _tmp->work += 1;
          checked_pthread_mutex_unlock(&(_tmp->lk));
        }
      },
      top.groups)
    );
  top.groupThrdOps = nullStmt();
  top.groupPostOps = foldStmt(
    map(\g::Expr -> ableC_Stmt {
        {
          struct __posix_sync* _tmp = (struct __posix_sync*)
            $Expr{getReference(decorate g with {env=top.env;
                          controlStmtContext=initialControlStmtContext;})};
          checked_pthread_mutex_lock(&(_tmp->lk));
          _tmp->work -= 1;
          if (_tmp->work == 0) {
            checked_pthread_cond_broadcast(&(_tmp->cv));
          }
          checked_pthread_mutex_unlock(&(_tmp->lk));
        }
      },
      top.groups)
    );

  top.syncThreads = foldStmt(
    map(\t::Expr -> ableC_Stmt {
        {
          struct __posix_sync* _tmp = (struct __posix_sync*)
            $Expr{getReference(decorate t with {env=top.env;
                          controlStmtContext=initialControlStmtContext;})};
          checked_pthread_mutex_lock(&(_tmp->lk));
          _tmp->waiting += 1;
          while (_tmp->work > 0) {
            checked_pthread_cond_wait(&(_tmp->cv), &(_tmp->lk));
          }

          _tmp->waiting -= 1;
          if (_tmp->waiting == 0) {
            _tmp->work = -1;
          }

          checked_pthread_mutex_unlock(&(_tmp->lk));
        }
      },
      top.threads)
    );
  top.syncGroups = foldStmt(
    map(\g::Expr -> ableC_Stmt {
        {
          struct __posix_sync* _tmp = (struct __posix_sync*)
            $Expr{getReference(decorate g with {env=top.env;
                          controlStmtContext=initialControlStmtContext;})};
          checked_pthread_mutex_lock(&(_tmp->lk));
          _tmp->waiting += 1;
          while (_tmp->work > 0) {
            checked_pthread_cond_wait(&(_tmp->cv), &(_tmp->lk));
          }

          _tmp->waiting -= 1;
          checked_pthread_mutex_unlock(&(_tmp->lk));
        }
      },
      top.groups)
    );

  top.initializeThread = initializePosixThread(_, _, location=_);
  top.threadDeleteProd = just(posixDeleteThread);
  top.initializeGroup = initializePosixGroup(_, _, location=_);
  top.groupDeleteProd = just(posixDeleteGroup);
}

abstract production initializePosixThread
top::Expr ::= l::Expr args::Exprs
{
  top.pp = ppConcat([l.pp, text("="), text("new posix thread"),
      parens(ppImplode(text(","), args.pps))]);

  propagate controlStmtContext, env;

  local localErrors :: [Message] =
    args.errors
    ++
    case args of
    | nilExpr() -> []
    | _ -> [err(top.location, "POSIX thread should be initialized with no arguments")]
    end;

  local lhs::Expr = exprAsType(l, extType(nilQualifier(),
        refIdExtType(structSEU(), just("__posix_sync"),
          "edu:umn:cs:melt:exts:ableC:parallel:impl:posix:sync")),
        location=top.location);

  forwards to
    if !null(localErrors)
    then errorExpr(localErrors, location=top.location)
    else ableC_Expr {
      ({
        checked_pthread_mutex_init(&($Expr{lhs}.lk), (void*) 0);
        checked_pthread_cond_init(&($Expr{lhs}.cv), (void*) 0);
        $Expr{lhs}.work = -1;
        $Expr{lhs}.waiting = 0;
        $Expr{l};
      })
    };
}

abstract production posixDeleteThread
top::Stmt ::= e::Expr
{
  top.pp = ppConcat([text("delete"), e.pp]);
  top.functionDefs := [];
  top.labelDefs := [];

  propagate controlStmtContext, env;

  forwards to
    if !null(e.errors)
    then warnStmt(e.errors)
    else ableC_Stmt {
      {
        struct __posix_sync* _tmp = (struct __posix_sync*) $Expr{getReference(e)};
        checked_pthread_mutex_lock(&(_tmp->lk));
        if (__builtin_expect(_tmp->work > 0 || _tmp->waiting != 0, 0)) {
          fprintf(stderr, $stringLiteralExpr{s"Attempted to delete a thread associated with remaining or unsynchronized work (${e.location.unparse})\n"});
          exit(-1);
        }
        checked_pthread_mutex_unlock(&(_tmp->lk)); // undefined behavior to destroy held mutex
        checked_pthread_mutex_destroy(&(_tmp->lk));
        checked_pthread_cond_destroy(&(_tmp->cv));
      }
    };
}

abstract production initializePosixGroup
top::Expr ::= l::Expr args::Exprs
{
  top.pp = ppConcat([l.pp, text("="), text("new posix group"),
    parens(ppImplode(text(","), args.pps))]);

  propagate controlStmtContext, env;

  local localErrors :: [Message] =
    args.errors
    ++
    case args of
    | nilExpr() -> []
    | _ -> [err(top.location, "POSIX group should be initialized with no arguments")]
    end;

  local lhs::Expr = exprAsType(l, extType(nilQualifier(),
        refIdExtType(structSEU(), just("__posix_sync"),
          "edu:umn:cs:melt:exts:ableC:parallel:impl:posix:sync")),
        location=top.location);

  forwards to
    if !null(localErrors)
    then errorExpr(localErrors, location=top.location)
    else ableC_Expr {
      ({
        checked_pthread_mutex_init(&($Expr{lhs}.lk), (void*) 0);
        checked_pthread_cond_init(&($Expr{lhs}.cv), (void*) 0);
        $Expr{lhs}.work = 0;
        $Expr{lhs}.waiting = 0;
        $Expr{lhs};
      })
    };
}

abstract production posixDeleteGroup
top::Stmt ::= e::Expr
{
  top.pp = ppConcat([text("delete"), e.pp]);
  top.functionDefs := [];
  top.labelDefs := [];

  propagate controlStmtContext, env;

  forwards to
    if !null(e.errors)
    then warnStmt(e.errors)
    else ableC_Stmt {
      {
        struct __posix_sync* _tmp = (struct __posix_sync*) $Expr{getReference(e)};
        checked_pthread_mutex_lock(&(_tmp->lk));
        if (__builtin_expect(_tmp->work != 0 || _tmp->waiting != 0, 0)) {
          fprintf(stderr, $stringLiteralExpr{s"Attempted to delete a group with remaining or incompletely synchronized work (${e.location.unparse})\n"});
          exit(-1);
        }
        checked_pthread_mutex_unlock(&(_tmp->lk)); // undefined behavior to destroy held mutex
        checked_pthread_mutex_destroy(&(_tmp->lk));
        checked_pthread_cond_destroy(&(_tmp->cv));
      }
    };
}
