grammar edu:umn:cs:melt:exts:ableC:parallel:impl:blocking;

abstract production blockingSyncSystem
top::SyncSystem ::=
{
  top.parName = "blocking";

  top.threadType = 
    (decorate
      refIdExtType(structSEU(), just("__blocking_sync"),
        "edu:umn:cs:melt:exts:ableC:parallel:blocking:sync")
    with {givenQualifiers=nilQualifier();}).host;
  
  top.groupType =
    (decorate
      refIdExtType(structSEU(), just("__blocking_sync"),
        "edu:umn:cs:melt:exts:ableC:parallel:blocking:sync")
    with {givenQualifiers=nilQualifier();}).host;

  top.threadBefrOps = foldStmt(
    map(\t::Expr -> ableC_Stmt {
        {
          struct __blocking_sync* _tmp = (struct __blocking_sync*) 
            $Expr{getReference(decorate t with {env=top.env; 
                                controlStmtContext=initialControlStmtContext;})};
          __ableC_spinlock_acquire(&(_tmp->spinlock));
          if (__builtin_expect(_tmp->work != -1 || _tmp->waiting != 0 || _tmp->waiting_head != (void*) 0, 0)) {
            fprintf(stderr, $stringLiteralExpr{s"Attempted to used an in-use thread object ({t.location.unparse})\n"});
            exit(-1);
          }
          _tmp->work = 1;
          __ableC_spinlock_release(&(_tmp->spinlock));
        }
      },
      top.threads)
    );
  top.threadThrdOps = nullStmt();
  top.threadPostOps = foldStmt(
    map(\t::Expr -> ableC_Stmt {
        {
          struct __blocking_sync* _tmp = (struct __blocking_sync*) 
            $Expr{getReference(decorate t with {env=top.env; 
                                controlStmtContext=initialControlStmtContext;})};
          __ableC_spinlock_acquire(&(_tmp->spinlock));
          _tmp->work = 0;

          struct __ableC_tcb* wake_list = _tmp->waiting_head;
          _tmp->waiting_head = (void*) 0;
          __ableC_spinlock_release(&(_tmp->spinlock));

          // Do this to avoid waking up threads while holding a spinlock
          while (wake_list != (void*) 0) {
            wake_list->system->unblock(wake_list);
            wake_list = wake_list->next;
          }
        }
      },
      top.threads)
    );

  top.groupBefrOps = foldStmt(
    map(\g::Expr -> ableC_Stmt {
        {
          struct __blocking_sync* _tmp = (struct __blocking_sync*)
            $Expr{getReference(decorate g with {env=top.env;
                                controlStmtContext=initialControlStmtContext;})};

          __ableC_spinlock_acquire(&(_tmp->spinlock));
          // TODO: We would like some check to avoid adding threads to a group being waited on if there's a possible race condition (this would involve knowing if the current thread is in the group)
          _tmp->work += 1;
          __ableC_spinlock_release(&(_tmp->spinlock));
        }
      },
      top.groups)
    );
  top.groupThrdOps = nullStmt();
  top.groupPostOps = foldStmt(
    map(\g::Expr -> ableC_Stmt {
        {
          struct __blocking_sync* _tmp = (struct __blocking_sync*)
            $Expr{getReference(decorate g with {env=top.env;
                                controlStmtContext=initialControlStmtContext;})};
          
          __ableC_spinlock_acquire(&(_tmp->spinlock));
          _tmp->work -= 1;
          if (_tmp->work == 0) {
            struct __ableC_tcb* wake_list = _tmp->waiting_head;
            _tmp->waiting_head = (void*) 0;
            __ableC_spinlock_release(&(_tmp->spinlock));

            // Do this to avoid waking threads up while holding a spinlock
            while (wake_list != (void*) 0) {
              wake_list->system->unblock(wake_list);
              wake_list = wake_list->next;
            }
          } else {
            __ableC_spinlock_release(&(_tmp->spinlock));
          }
        }
      },
      top.groups)
    );

  top.syncThreads = foldStmt(
    map(\t::Expr -> ableC_Stmt {
        {
          struct __blocking_sync* _tmp = (struct __blocking_sync*)
            $Expr{getReference(decorate t with {env=top.env;
                                controlStmtContext=initialControlStmtContext;})};
          
          __ableC_spinlock_acquire(&(_tmp->spinlock));  
          _tmp->waiting += 1;

          while (_tmp->work > 0) {
            __ableC_thread_tcb->next = _tmp->waiting_head;
            _tmp->waiting_head = __ableC_thread_tcb;

            __ableC_spinlock_release(&(_tmp->spinlock));
            
            __ableC_thread_tcb->system->block(__ableC_thread_tcb);

            __ableC_spinlock_acquire(&(_tmp->spinlock));
          }

          _tmp->waiting -= 1;
          if (_tmp->waiting == 0) {
            _tmp->work = -1;
          }

          __ableC_spinlock_release(&(_tmp->spinlock));
        }
      },
      top.threads)
    );
  top.syncGroups = foldStmt(
    map(\g::Expr -> ableC_Stmt {
        {
          struct __blocking_sync* _tmp = (struct __blocking_sync*)
            $Expr{getReference(decorate g with {env=top.env;
                                controlStmtContext=initialControlStmtContext;})};
          
          __ableC_spinlock_acquire(&(_tmp->spinlock));
          _tmp->waiting += 1;

          while (_tmp->work > 0) {
            __ableC_thread_tcb->next = _tmp->waiting_head;
            _tmp->waiting_head = __ableC_thread_tcb;

            __ableC_spinlock_release(&(_tmp->spinlock));

            __ableC_thread_tcb->system->block(__ableC_thread_tcb);

            __ableC_spinlock_acquire(&(_tmp->spinlock));
          }

          _tmp->waiting -= 1;
          __ableC_spinlock_release(&(_tmp->spinlock));
        }
      },
      top.groups)
    );

  top.initializeThread = initializeBlockingThread(_, _, location=_);
  top.threadDeleteProd = just(blockingDeleteThread);
  top.initializeGroup = initializeBlockingGroup(_, _, location=_);
  top.groupDeleteProd = just(blockingDeleteGroup);
}

abstract production initializeBlockingThread
top::Expr ::= l::Expr args::Exprs
{
  top.pp = ppConcat([l.pp, text("="), text("new blocking thread"),
      parens(ppImplode(text(","), args.pps))]);

  local localErrors :: [Message] =
    args.errors
    ++
    case args of
    | nilExpr() -> []
    | _ -> [err(top.location, "blocking thread should be initialized with no arguments")]
    end;

  local lhs::Expr = exprAsType(l, extType(nilQualifier(),
                      refIdExtType(structSEU(), just("__blocking_sync"),
                        "edu:umn:cs:melt:exts:ableC:parallel:blocking:sync")),
                      location=top.location);

  forwards to
    if !null(localErrors)
    then errorExpr(localErrors, location=top.location)
    else ableC_Expr {
        ({
          $Expr{lhs}.spinlock = 0;
          $Expr{lhs}.work = -1;
          $Expr{lhs}.waiting = 0;
          $Expr{lhs}.waiting_head = (void*) 0;
          $Expr{l};
        })
      };
}

abstract production blockingDeleteThread
top::Stmt ::= e::Expr
{
  top.pp = ppConcat([text("delete"), e.pp]);
  top.functionDefs := [];
  top.labelDefs := [];

  forwards to
    if !null(e.errors)
    then warnStmt(e.errors)
    else ableC_Stmt {
      {
        struct __blocking_sync* _tmp = (struct __blocking_sync*) $Expr{getReference(e)};
        __ableC_spinlock_acquire(&(_tmp->spinlock));  
        if (__builtin_expect(_tmp->work > 0 || _tmp->waiting != 0, 0)) {
          fprintf(stderr, $stringLiteralExpr{s"Attempted to delete a thread associated with remaining or unsynchronized work (${e.location.unparse})\n"});
          exit(-1);
        }
      }
    };
}

abstract production initializeBlockingGroup
top::Expr ::= l::Expr args::Exprs
{
  top.pp = ppConcat([l.pp, text("="), text("new blocking group"),
      parens(ppImplode(text(","), args.pps))]);

  local localErrors :: [Message] =
    args.errors
    ++
    case args of
    | nilExpr() -> []
    | _ -> [err(top.location, "blocking group should be initialized with no arguments")]
    end;

  local lhs::Expr = exprAsType(l, extType(nilQualifier(),
                      refIdExtType(structSEU(), just("__blocking_sync"),
                        "edu:umn:cs:melt:exts:ableC:parallel:blocking:sync")),
                      location=top.location);

  forwards to
    if !null(localErrors)
    then errorExpr(localErrors, location=top.location)
    else ableC_Expr {
        ({
          $Expr{lhs}.spinlock = 0;
          $Expr{lhs}.work = 0;
          $Expr{lhs}.waiting = 0;
          $Expr{lhs}.waiting_head = (void*) 0;
          $Expr{l};
        })
      };
}

abstract production blockingDeleteGroup
top::Stmt ::= e::Expr
{
  top.pp = ppConcat([text("delete"), e.pp]);
  top.functionDefs := [];
  top.labelDefs := [];

  forwards to
    if !null(e.errors)
    then warnStmt(e.errors)
    else ableC_Stmt {
      {
        struct __blocking_sync* _tmp = (struct __blocking_sync*) $Expr{getReference(e)};
        __ableC_spinlock_acquire(&(_tmp->spinlock));
        if (__builtin_expect(_tmp->work != 0 || _tmp->waiting != 0, 0)) {
          fprintf(stderr, $stringLiteralExpr{s"Attempted to delete a group with remaining or incompletely synchronized work (${e.location.unparse})\n"});
          exit(-1);
        }
      }
    };
}
