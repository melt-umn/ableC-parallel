grammar edu:umn:cs:melt:exts:ableC:parallel:exts:balancer:uses:bworkstlr;

abstract production bworkstlrParallelSystem
top::ParallelSystem ::= 
{
  top.parName = "bworkstlr";

  top.fSpawn = workstlrSpawn;
  top.fFor = workstlrParFor;
  top.newProd = just(\a::Exprs l::Location -> bworkstlrParallelNew(a, location=l));
  top.deleteProd = just(bworkstlrParallelDelete);
}

aspect production systemNumbering
top::SystemNumbering ::=
{
  systems <- [bworkstlrParallelSystem()];
}

abstract production bworkstlrParallelNew
top::Expr ::= args::Exprs
{
  local localErrors :: [Message] =
    args.errors 
    ++
    case args of
    | consExpr(e, consExpr(n, nilExpr())) ->
        case (decorate e with {env=top.env;
                controlStmtContext=top.controlStmtContext;}).typerep of
        | extType(_, balancerType(_)) -> []
        | _ -> [err(top.location, "BWorkstlr's first argument should be a balancer")]
        end
        ++
        if (decorate n with {env=top.env;
                controlStmtContext=top.controlStmtContext;}).typerep.isIntegerType
        then []
        else [err(top.location, "BWorkstlr's second argument should be an integer")]
    | _ -> [err(top.location, "BWorkstlr parallel system should be initialized with a balancer and a maximum number of threads as its arguments")]
    end;

  top.pp = ppConcat([text("new bworkstlr parallel"), 
    parens(ppImplode(text(", "), args.pps))]);

  local nmbrg::SystemNumbering = systemNumbering();
  nmbrg.lookupParName = "workstlr";

  local balancer :: Expr = case args of consExpr(e, _) -> e
                           | _ -> error("Error in arguments reported via errors attribute") end;
  local numThds :: Expr = case args of consExpr(_, consExpr(n, _)) -> n
                          | _ -> error("Error in arguments reported via errors attribute") end;
  local sysIndex :: Integer = nmbrg.parNameIndex;

  forwards to 
    if !null(localErrors)
    then errorExpr(localErrors, location=top.location)
    else ableC_Expr {
      ({
        int _max_threads = $Expr{numThds};

        if (__builtin_expect(_max_threads < 1, 0)) {
          fprintf(stderr,
            $stringLiteralExpr{s"Attempted to create a bworkstlr system with a non-positive maximum number of threads (${top.location.unparse})\n"});
          exit(-1);
        }

        struct __ableC_system_info* _res =
          start_bworkstlr_system((struct __balancer*) &$Expr{balancer},
                                  _max_threads, $intLiteralExpr{sysIndex});
        
        if (__builtin_expect(_res == (void*) 0, 0)) {
          fprintf(stderr,
            $stringLiteralExpr{s"Failed to start a bworkstlr system (${top.location.unparse})\n"});
          exit(-1);
        }

        _res;
      })
    };
}

abstract production bworkstlrParallelDelete
top::Stmt ::= e::Expr
{
  top.pp = ppConcat([text("delete"), e.pp]);
  top.functionDefs := [];
  top.labelDefs := [];

  forwards to
    if !null(e.errors)
    then warnStmt(e.errors)
    else ableC_Stmt { {
        struct __ableC_system_info* _sys =
          (struct __ableC_system_info*) $Expr{e};
        stop_bworkstlr_system(_sys);
      } };
}
