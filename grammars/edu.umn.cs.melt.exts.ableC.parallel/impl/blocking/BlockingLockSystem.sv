grammar edu:umn:cs:melt:exts:ableC:parallel:impl:blocking;

abstract production blockingLockSystem
top::LockSystem ::=
{
  local builtin :: Location = builtinLoc("parallel-blocking");

  top.parName = "blocking";

  top.lockType = 
    (decorate
      refIdExtType(structSEU(), just("__blocking_lock"),
        "edu:umn:cs:melt:exts:ableC:parallel:blocking:lock")
    with {givenQualifiers=nilQualifier();}).host;

  top.condType =
    (decorate
      refIdExtType(structSEU(), just("__blocking_condvar"),
        "edu:umn:cs:melt:exts:ableC:parallel:blocking:condvar")
    with {givenQualifiers=nilQualifier();}).host;
  
  top.acquireLocks =
    foldStmt(
      map(
        \e::Expr -> ableC_Stmt {
          {
            struct __blocking_lock* _tmp = (struct __blocking_lock*) 
              $Expr{getReference(decorate e with {env=top.env; 
                controlStmtContext = initialControlStmtContext;})};

            if (__builtin_expect(_tmp->cur_holding == __ableC_thread_tcb, 0)) {
              fprintf(stderr,
                $stringLiteralExpr{s"Attempted to acquire a lock already held by the thread (${e.location.unparse})\n"});
              exit(-1);
            }
            int status = 1;

            while (status != 0) {
              __ableC_spinlock_acquire(&(_tmp->spinlock));
              status = _tmp->status;
              _tmp->status = 1;

              if (status != 0) {
                __ableC_thread_tcb->next = (void*) 0;
                
                if (_tmp->waiting_head == (void*) 0) {
                  _tmp->waiting_head = __ableC_thread_tcb;
                  _tmp->waiting_tail = __ableC_thread_tcb;
                } else {
                  _tmp->waiting_tail->next = __ableC_thread_tcb;
                  _tmp->waiting_tail = __ableC_thread_tcb;
                }
              } else {
                _tmp->cur_holding = __ableC_thread_tcb;
              }

              __ableC_spinlock_release(&(_tmp->spinlock));

              if (status != 0) {
                __ableC_thread_tcb->system->block(__ableC_thread_tcb);
              }
            }
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
            struct __blocking_lock* _tmp = (struct __blocking_lock*) 
              $Expr{getReference(decorate e with {env=top.env;
                controlStmtContext = initialControlStmtContext;})};

            if (__builtin_expect(_tmp->cur_holding != __ableC_thread_tcb, 0)) {
              fprintf(stderr, 
                $stringLiteralExpr{s"Attempted to release a lock not held by this thread (${e.location.unparse})\n"});
              exit(-1);
            }

            __ableC_spinlock_acquire(&(_tmp->spinlock));

            _tmp->status = 0;
            _tmp->cur_holding = (void*) 0;

            if (_tmp->waiting_head != (void*) 0) {
              struct __ableC_tcb* next_thread = _tmp->waiting_head;
            
              _tmp->waiting_head = next_thread->next;
              if (next_thread->next == (void*) 0) {
                _tmp->waiting_tail = (void*) 0;
              }

              // Release the spinlock before waking the other thread, to avoid
              // waking it while holding a spinlock
              __ableC_spinlock_release(&(_tmp->spinlock));
              
              next_thread->system->unblock(next_thread);
            } else {
              __ableC_spinlock_release(&(_tmp->spinlock));
            }
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
        controlStmtContext = initialControlStmtContext;}),    
      location=builtin
    );

  local loc :: String = top.condvar.location.unparse;

  top.waitCV = ableC_Stmt {
      {
        struct __blocking_condvar* _tmp = $Expr{refCV};
        struct __blocking_lock* _lk = _tmp->lk;
        
        if (__builtin_expect(_lk->cur_holding != __ableC_thread_tcb, 0)) {
          fprintf(stderr, $stringLiteralExpr{s"Attempted to wait on a condvar without holding the lock (${loc})\n"});
          exit(-1);
        }

        __ableC_spinlock_acquire(&(_lk->spinlock));

        __ableC_thread_tcb->next = (void*) 0;
        if (_tmp->waiting_head == (void*) 0) {
          _tmp->waiting_head = __ableC_thread_tcb;
          _tmp->waiting_tail = __ableC_thread_tcb;
        } else {
          _tmp->waiting_tail->next = __ableC_thread_tcb;
          _tmp->waiting_tail = __ableC_thread_tcb;
        }

        _lk->status = 0;
        _lk->cur_holding = (void*) 0;

        struct __ableC_tcb* next_thread = _lk->waiting_head;
        if (next_thread != (void*) 0) {
        
          _lk->waiting_head = next_thread->next;
          if (next_thread->next == (void*) 0) {
            _lk->waiting_tail = (void*) 0;
          }

          __ableC_spinlock_release(&(_lk->spinlock));
          next_thread->system->unblock(next_thread);
        } else {
          __ableC_spinlock_release(&(_lk->spinlock));
        }

        __ableC_thread_tcb->system->block(__ableC_thread_tcb);
            
        int status = 1;

        while (status != 0) {
          __ableC_spinlock_acquire(&(_lk->spinlock));
          status = _lk->status;
          _lk->status = 1;

          if (status != 0) {
            __ableC_thread_tcb->next = (void*) 0;
            
            if (_lk->waiting_head == (void*) 0) {
              _lk->waiting_head = __ableC_thread_tcb;
              _lk->waiting_tail = __ableC_thread_tcb;
            } else {
              _lk->waiting_tail->next = __ableC_thread_tcb;
              _lk->waiting_tail = __ableC_thread_tcb;
            }
          } else {
            _lk->cur_holding = __ableC_thread_tcb;
          }

          __ableC_spinlock_release(&(_lk->spinlock));

          if (status != 0) {
            __ableC_thread_tcb->system->block(__ableC_thread_tcb);
          }
        }
      }
    };

  top.signalCV = ableC_Stmt {
      {
        struct __blocking_condvar* _tmp = $Expr{refCV};
        
        if (__builtin_expect(_tmp->lk->cur_holding != __ableC_thread_tcb, 0)) {
          fprintf(stderr, $stringLiteralExpr{s"Attempted to signal a condvar without holding the lock (${loc})\n"});
          exit(-1);
        }

        if (_tmp->waiting_head != (void*) 0) {
          struct __ableC_tcb* next_thread = _tmp->waiting_head;
        
          _tmp->waiting_head = next_thread->next;
          if (next_thread->next == (void*) 0) {
            _tmp->waiting_tail = (void*) 0;
          }

          next_thread->system->unblock(next_thread);
        }
      }
    };
  
  top.broadcastCV = ableC_Stmt {
      {
        struct __blocking_condvar* _tmp = $Expr{refCV};
        
        if (__builtin_expect(_tmp->lk->cur_holding != __ableC_thread_tcb, 0)) {
          fprintf(stderr, $stringLiteralExpr{s"Attempted to broadcast a condvar without holding the lock (${loc})\n"});
          exit(-1);
        }

        while (_tmp->waiting_head != (void*) 0) {
          struct __ableC_tcb* next_thread = _tmp->waiting_head;
        
          _tmp->waiting_head = next_thread->next;
          if (next_thread->next == (void*) 0) {
            _tmp->waiting_tail = (void*) 0;
          }

          next_thread->system->unblock(next_thread);
        }
      }
    };

  top.initializeLock = initializeBlockingLock(_, _, location=_);
  top.lockDeleteProd = just(blockingLockDelete);
  top.initializeCondvar = initializeBlockingCondvar(_, _, location=_);
  top.condvarDeleteProd = just(blockingCondvarDelete);
}

abstract production initializeBlockingLock
top::Expr ::= l::Expr args::Exprs
{
  local localErrors :: [Message] =
    args.errors
    ++
    case args of
    | nilExpr() -> []
    | _ -> [err(top.location, "Blocking locks should be initialized with no arguments")]
    end;

  top.pp = ppConcat([l.pp, text("="), text("new blocking lock()")]);

  local lhs::Expr = exprAsType(l, extType(nilQualifier(),
                      refIdExtType(structSEU(), just("__blocking_lock"),
                        "edu:umn:cs:melt:exts:ableC:parallel:blocking:lock")),
                      location=top.location);

  forwards to
    if !null(localErrors)
    then errorExpr(localErrors, location=top.location)
    else ableC_Expr {
        ({
          $Expr{lhs}.spinlock = 0;
          $Expr{lhs}.status = 0;
          $Expr{lhs}.cur_holding = (void*) 0;
          $Expr{lhs}.waiting_head = (void*) 0;
          $Expr{lhs}.waiting_tail = (void*) 0;
          $Expr{l};
        })
      };
}

abstract production blockingLockDelete
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
          struct __blocking_lock* _tmp = (struct __blocking_lock*) $Expr{refVal};

          if (_tmp->cur_holding != (void*) 0 || _tmp->waiting_head != (void*) 0 || _tmp->waiting_tail != (void*) 0) {
            fprintf(stderr, $stringLiteralExpr{s"Attempted to delete held lock (${val.location.unparse})\n"});
            exit(-1);
          }
        }
      };
}

abstract production initializeBlockingCondvar
top::Expr ::= l::Expr args::Exprs
{
  top.pp = ppConcat([l.pp, text("="), text("new blocking condvar"),
    parens(ppImplode(text(","), args.pps))]);
  
  local localErrors :: [Message] =
    args.errors
    ++
    case args of
    | consExpr(e, nilExpr()) ->
      case (decorate e with {env=top.env; controlStmtContext=initialControlStmtContext;}).typerep of
      | pointerType(_, extType(_, lockType(s))) when s.parName == "blocking" -> []
      | _ -> [err(top.location, "Blocking condvar initialization expects a blocking lock* as the argument")]
      end
    | _ -> [err(top.location, "Blocking condvar should be initialized with a single argument")]
    end;

  local lock :: Expr =
    case args of
    | consExpr(e, _) -> e
    | _ -> error("Wrong arguments should be caught in errors attribute")
    end;

  local lhs::Expr = exprAsType(l, extType(nilQualifier(),
                      refIdExtType(structSEU(), just("__blocking_condvar"),
                        "edu:umn:cs:melt:exts:ableC:parallel:blocking:condvar")),
                      location=top.location);

  forwards to
    if !null(localErrors)
    then errorExpr(localErrors, location=top.location)
    else ableC_Expr {
      ({
        $Expr{lhs}.lk = (struct __blocking_lock*) $Expr{lock};
        $Expr{lhs}.waiting_head = (void*) 0;
        $Expr{lhs}.waiting_tail = (void*) 0;
      })
      };
}

abstract production blockingCondvarDelete
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
          struct __blocking_condvar* _tmp = (struct __blocking_condvar*) $Expr{refVal};
          if (_tmp->waiting_head != (void*) 0 || _tmp->waiting_tail != (void*) 0) {
            fprintf(stderr, $stringLiteralExpr{s"Attempted to delete an in-use condvar (${val.location.unparse})\n"});
            exit(-1);
          }
          _tmp->lk = (void*) 0;
        }
      };
}
