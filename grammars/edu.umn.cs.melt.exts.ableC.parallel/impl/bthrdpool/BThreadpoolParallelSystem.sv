grammar edu:umn:cs:melt:exts:ableC:parallel:impl:bthrdpool;

abstract production bthrdpoolParallelSystem
top::ParallelSystem ::= 
{
  top.parName = "bthrdpool";

  top.fSpawn = thrdpoolSpawn;
  top.fFor = thrdpoolFor;
  top.newProd = just(\a::Exprs l::Location -> bthrdpoolParallelNew(a, location=l));
  top.deleteProd = just(bthrdpoolParallelDelete);
  top.transFunc = parallelFuncToC;
}

aspect production systemNumbering
top::SystemNumbering ::=
{
  systems <- [bthrdpoolParallelSystem()];
}

abstract production bthrdpoolParallelNew
top::Expr ::= args::Exprs
{
  local localErrors :: [Message] =
    args.errors 
    ++
    case args of
    | consExpr(e, nilExpr()) ->
        case (decorate e with {env=top.env;
                controlStmtContext=top.controlStmtContext;}).typerep of
        | extType(_, balancerType(_)) -> []
        | _ -> [err(top.location, "BThreadpool's argument should be a balancer")]
        end
    | _ -> [err(top.location, "BThrdpool parallel system should be initialized with a balancer as its one argument")]
    end;

  top.pp = ppConcat([text("new bthrdpool parallel"), 
    parens(ppImplode(text(", "), args.pps))]);

  local nmbrg::SystemNumbering = systemNumbering();
  nmbrg.lookupParName = "bthrdpool";

  local balancer :: Expr = case args of consExpr(e, nilExpr()) -> e
                           | _ -> error("Error in arguments reported via errors attribute") end;
  local sysIndex :: Integer = nmbrg.parNameIndex;

  propagate controlStmtContext, env;

  forwards to 
    if !null(localErrors)
    then errorExpr(localErrors, location=top.location)
    else ableC_Expr {
      ({
        struct __ableC_system_info* ptr = malloc(sizeof(struct __ableC_system_info));

        ptr->system_id = $intLiteralExpr{sysIndex};
        // TODO: Different blocker, maybe?
        ptr->block = __thrdpool_block_func;
        ptr->unblock = __thrdpool_unblock_func;
        
        struct __bthrdpool_system_info* info = malloc(sizeof(struct __bthrdpool_system_info));
        info->num_thrds = 1;
        info->bal = (struct __balancer*) &$Expr{balancer};
        info->shutdown = 0;

        info->threads = (void*) 0;

        ptr->system_data = info;
        
        checked_pthread_mutex_init(&(info->lk), (void*) 0);
        checked_pthread_cond_init(&(info->cv), (void*) 0);
        info->work_head = (void*) 0;
        info->work_tail = (void*) 0;
        
        info->bal->demand_thread(info->bal, __bthrdpool_launcher, ptr);

        ptr;
      })
    };
}

abstract production bthrdpoolParallelDelete
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
          struct __ableC_system_info* _sys = 
            (struct __ableC_system_info*) $Expr{e};
          struct __bthrdpool_system_info* _pool =
            (struct __bthrdpool_system_info*) _sys->system_data;

          checked_pthread_mutex_lock(&(_pool->lk));

          if (__builtin_expect(_pool->work_head != (void*) 0, 0)) {
            fprintf(stderr, 
              $stringLiteralExpr{s"Attempted to delete a thread pool with remaining work (${e.location.unparse})\n"});
            exit(-1);
          }

          _pool->shutdown = 1;

          checked_pthread_cond_broadcast(&(_pool->cv));
          checked_pthread_mutex_unlock(&(_pool->lk));

          while (_pool->num_thrds > 0) ;

          checked_pthread_mutex_destroy(&(_pool->lk));
          checked_pthread_cond_destroy(&(_pool->cv));

          free(_pool);
          free(_sys);
        }
      };
}
