grammar edu:umn:cs:melt:exts:ableC:parallel:impl:posix;

abstract production posixLockSystem
top::LockSystem ::=
{
  local builtin :: Location = builtinLoc("parallel-posix");

  top.parName = "posix";

  top.lockType =
    (decorate
      refIdExtType(structSEU(), just("__posix_mutex"),
        "edu:umn:cs:melt:exts:ableC:parallel:impl:posix:mutex")
    with {givenQualifiers=nilQualifier();}).host;

  top.condType =
    (decorate
      refIdExtType(structSEU(), just("__posix_condvar"),
        "edu:umn:cs:melt:exts:ableC:parallel:impl:posix:condvar")
    with {givenQualifiers=nilQualifier();}).host;

  top.acquireLocks =
    foldStmt(
      map(
        \e::Expr -> ableC_Stmt {
          {
            struct __posix_mutex* _tmp = (struct __posix_mutex*)
              $Expr{getReference(decorate e with {env=top.env;
                                  controlStmtContext=initialControlStmtContext;})};

            if (__builtin_expect(_tmp->cur_holding == __ableC_thread_tcb, 0)) {
              fprintf(stderr,
                $stringLiteralExpr{s"Attempted to acquire a lock already held by the thread (${e.location.unparse})\n"});
              exit(-1);
            }

            checked_pthread_mutex_lock(&(_tmp->lk));
            _tmp->cur_holding = __ableC_thread_tcb;
          }
        },
        top.locks
      )
    );

  top.releaseLocks =
    foldStmt(
      map(
        \e::Expr -> ableC_Stmt {
          {
            struct __posix_mutex* _tmp = (struct __posix_mutex*)
              $Expr{getReference(decorate e with {env=top.env;
                                  controlStmtContext=initialControlStmtContext;})};

            if (__builtin_expect(_tmp->cur_holding != __ableC_thread_tcb, 0)) {
              fprintf(stderr,
                $stringLiteralExpr{s"Attempted to release a lock not held by this thread (${e.location.unparse})\n"});
              exit(-1);
            }

            _tmp->cur_holding = (void*) 0;
            checked_pthread_mutex_unlock(&(_tmp->lk));
          }
        },
        top.locks
      )
    );


  local refCV :: Expr =
    explicitCastExpr(
      typeName(top.condType.baseTypeExpr,
        pointerTypeExpr(nilQualifier(), top.condType.typeModifierExpr)),
      getReference(decorate top.condvar with {env=top.env;
                              controlStmtContext=initialControlStmtContext;}),
      location=builtin
    );

  local loc :: String = top.condvar.location.unparse;

  top.waitCV = ableC_Stmt {
      {
        struct __posix_condvar* _tmp = $Expr{refCV};

        if (__builtin_expect(_tmp->lk->cur_holding != __ableC_thread_tcb, 0)) {
          fprintf(stderr, $stringLiteralExpr{s"Attempted to wait on a condvar without holding the lock (${loc})\n"});
          exit(-1);
        }

        _tmp->lk->cur_holding = (void*) 0;
        checked_pthread_cond_wait(&(_tmp->cv), &(_tmp->lk->lk));
        _tmp->lk->cur_holding = __ableC_thread_tcb;
      }
    };

  top.signalCV = ableC_Stmt {
      {
        struct __posix_condvar* _tmp = $Expr{refCV};
        if (__builtin_expect(_tmp->lk->cur_holding != __ableC_thread_tcb, 0)) {
          fprintf(stderr, $stringLiteralExpr{s"Attempted to signal a condvar without holding the lock (${loc})\n"});
          exit(-1);
        }

        checked_pthread_cond_signal(&(_tmp->cv));
      }
    };

  top.broadcastCV = ableC_Stmt {
      {
        struct __posix_condvar* _tmp = $Expr{refCV};
        if (__builtin_expect(_tmp->lk->cur_holding != __ableC_thread_tcb, 0)) {
          fprintf(stderr, $stringLiteralExpr{s"Attempted to broadcast a condvar without holding the lock (${loc})\n"});
          exit(-1);
        }

        checked_pthread_cond_broadcast(&(_tmp->cv));
      }
    };

  top.initializeLock = initializePosixLock(_, _, location=_);
  top.lockDeleteProd = just(posixLockDelete);
  top.initializeCondvar = initializePosixCondvar(_, _, location=_);
  top.condvarDeleteProd = just(posixCondvarDelete);
}

abstract production initializePosixLock
top::Expr ::= l::Expr args::Exprs
{
  local localErrors :: [Message] =
    args.errors
    ++
    case args of
    | nilExpr() -> []
    | _ -> [err(top.location, "POSIX locks should be initialized with no arguments")]
    end;

  top.pp = ppConcat([l.pp, text("="), text("new posix lock()")]);

  local lhs::Expr = exprAsType(l, extType(nilQualifier(),
        refIdExtType(structSEU(), just("__posix_mutex"),
          "edu:umn:cs:melt:exts:ableC:parallel:impl:posix:mutex")),
        location=top.location);

  forwards to
    if !null(localErrors)
    then errorExpr(localErrors, location=top.location)
    else ableC_Expr {
      ({
        $Expr{lhs}.cur_holding = (void*) 0;
        checked_pthread_mutex_init(&($Expr{lhs}.lk), (void*) 0);
        $Expr{l};
      })
    };
}

abstract production posixLockDelete
top::Stmt ::= val::Expr
{
  top.pp = ppConcat([text("delete"), val.pp]);
  top.functionDefs := [];
  top.labelDefs := [];

  val.env = top.env;
  val.controlStmtContext = top.controlStmtContext;

  local refVal :: Expr = getReference(val);

  forwards to
    if !null(val.errors)
    then warnStmt(val.errors)
    else ableC_Stmt {
        {
          struct __posix_mutex* _tmp = (struct __posix_mutex*) $Expr{refVal};
          if (_tmp->cur_holding != (void*) 0 || pthread_mutex_destroy(&(_tmp->lk))) {
            fprintf(stderr, $stringLiteralExpr{s"Attempted to delete held lock (${val.location.unparse})\n"});
            exit(-1);
          }
        }
      };
}

abstract production initializePosixCondvar
top::Expr ::= l::Expr args::Exprs
{
  top.pp = ppConcat([l.pp, text("="), text("new posix condvar"),
      parens(ppImplode(text(","), args.pps))]);

  local localErrors :: [Message] =
    args.errors
    ++
    case args of
    | consExpr(e, nilExpr()) ->
      case (decorate e with {env=top.env;
            controlStmtContext=initialControlStmtContext;}).typerep of
      | pointerType(_, extType(_, lockType(s))) when s.parName == "posix" -> []
      | _ -> [err(top.location, "POSIX condvar initialization expects a posix lock* as the argument")]
      end
    | _ -> [err(top.location, "POSIX condvar should be initialized with a single argument")]
    end;

  local lock :: Expr =
    case args of
    | consExpr(e, _) -> e
    | _ -> error("Incorrect arguments should be caught in errors attribute")
    end;

  local lhs::Expr = exprAsType(l, extType(nilQualifier(),
        refIdExtType(structSEU(), just("__posix_condvar"),
          "edu:umn:cs:melt:exts:ableC:parallel:impl:posix:condvar")),
        location=top.location);

  forwards to
    if !null(localErrors)
    then errorExpr(localErrors, location=top.location)
    else ableC_Expr {
        ({
          $Expr{lhs}.lk = (struct __posix_mutex*) $Expr{lock};
          int errnum = pthread_cond_init(&($Expr{lhs}.cv), (void*) 0);
          if (__builtin_expect(errnum, 0)) {
            fprintf(stderr, $stringLiteralExpr{s"Error in pthread_cond_init (${l.location.unparse}): %s\n"}, strerror(errnum));
            exit(-1);
          }
          $Expr{l};
        })
      };
}

abstract production posixCondvarDelete
top::Stmt ::= val::Expr
{
  top.pp = ppConcat([text("delete"), val.pp]);
  top.functionDefs := [];
  top.labelDefs := [];

  val.env = top.env;
  val.controlStmtContext = top.controlStmtContext;

  local refVal :: Expr = getReference(val);

  forwards to
    if !null(val.errors)
    then warnStmt(val.errors)
    else ableC_Stmt {
        {
          struct __posix_condvar* _tmp = (struct __posix_condvar*) $Expr{refVal};
          if (pthread_cond_destroy(&(_tmp->cv))) {
            fprintf(stderr, $stringLiteralExpr{s"Failed to delete condvar (${val.location.unparse})\n"});
            exit(-1);
          }
          _tmp->lk = (void*) 0;
        }
      };
}
