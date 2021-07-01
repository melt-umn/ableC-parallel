grammar edu:umn:cs:melt:exts:ableC:parallel:impl:fcfs;

abstract production fcfsBalancerSystem
top::BalancerSystem ::=
{
  top.parName = "fcfs";

  top.newProd = just(\es::Exprs loc::Location -> fcfsBalancerNew(es, location=loc));
  top.deleteProd = just(fcfsBalancerDelete);
}

abstract production fcfsBalancerNew
top::Expr ::= args::Exprs
{
  top.pp = ppConcat([text("new fcfs balancer"), parens(ppImplode(comma(), args.pps))]);

  local localErrors :: [Message] =
    case args of
    | consExpr(e, nilExpr()) ->
        if (decorate e with {env=top.env; controlStmtContext=top.controlStmtContext;})
            .typerep.isIntegerType
        then []
        else [err(top.location, "Argument to fcfs balancer initialization should be an integer")]
    | _ -> [err(top.location, "fcfs balancer requires one argument for initialization")]
    end;
  local arg :: Expr =
    case args of
    | consExpr(e, _) -> e
    | _ -> error("Forwards to errors, does not access this local")
    end;

  forwards to
    if !null(localErrors)
    then errorExpr(localErrors, location=top.location)
    else
      ableC_Expr { ({
        struct __fcfs_balancer* _sysInfo = malloc(sizeof(struct __fcfs_balancer));
        _sysInfo->maxThreads = $Expr{arg};
        _sysInfo->curThreads = 0;
        _sysInfo->recentRequests = 0;
        _sysInfo->numDemands = 0;
        checked_pthread_mutex_init(&(_sysInfo->lck), (void*) 0);
        checked_pthread_cond_init(&(_sysInfo->cv), (void*) 0);
        
        checked_pthread_attr_init(&(_sysInfo->attr));
        checked_pthread_attr_setdetachstate(&(_sysInfo->attr), PTHREAD_CREATE_DETACHED);

        struct __balancer _balancer;
        _balancer.request_thread = _fcfs_request_thread;
        _balancer.demand_thread =  _fcfs_demand_thread;
        _balancer.yield_thread = _fcfs_yield_thread;
        _balancer.release_thread = _fcfs_release_thread;
        _balancer.sysInfo = _sysInfo;
        
        _balancer;
      }) };
}

abstract production fcfsBalancerDelete
top::Stmt ::= arg::Expr
{
  forwards to
    ableC_Stmt { {
      struct __fcfs_balancer* _ptr =
        (struct __fcfs_balancer*) (((struct __balancer)$Expr{arg}).sysInfo);
      
      checked_pthread_mutex_lock(&(_ptr->lck));
      while (_ptr->curThreads > 0) {
        checked_pthread_mutex_unlock(&(_ptr->lck));
        checked_pthread_mutex_lock(&(_ptr->lck));
      }
      checked_pthread_mutex_unlock(&(_ptr->lck));

      checked_pthread_mutex_destroy(&(_ptr->lck));
      checked_pthread_cond_destroy(&(_ptr->cv));
      checked_pthread_attr_destroy(&(_ptr->attr));
      free(_ptr);
    } };
}
