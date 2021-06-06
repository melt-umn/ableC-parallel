grammar edu:umn:cs:melt:exts:ableC:parallel:impl:workstlr:func;

aspect production spawnTask
top::Stmt ::= expr::Expr annts::SpawnAnnotations
{
  top.workstlrParForConverted = top;

  -- A Workstlr spawn does not have a by ...; annotation and also shouldn't have
  -- any other annotations on it

  local fwrd :: Stmt = new(top.forward);
  fwrd.workstlrParFuncName = top.workstlrParFuncName;
  fwrd.workstlrParInitState = top.workstlrParInitState;
  fwrd.controlStmtContext = initialControlStmtContext;
  fwrd.env = top.env;

  -- Actually not sure if this is correct behavior for non-Workstlr spawn, since
  -- generally the expr will be lifted out of the Workstlr function
  top.workstlrParNeedStates = if annts.bySystem.isJust 
    then fwrd.workstlrParNeedStates else 1;
  
  local anyAnnotations :: Boolean =
    case annts of
    | nilSpawnAnnotations() -> false
    | _ -> true
    end;

  -- TODO: Add support for implicit inlets for += / -= / ...
  local validForm :: Boolean =
    case expr of
    | ovrld:eqExpr(_, directCallExpr(_, _)) -> true
    | directCallExpr(_, _) -> true
    | _ -> false
    end;

  local lhs :: Maybe<Expr> = 
    case expr of
    | ovrld:eqExpr(l, directCallExpr(_, _)) -> just(l)
    | _ -> nothing()
    end;
  local fname:: String = 
    case expr of
    | ovrld:eqExpr(_, directCallExpr(n, _)) -> n.name
    | directCallExpr(n, _) -> n.name
    | _ -> error("Invalid forms reported via errors attribute")
    end;
  local args :: Exprs =
    case expr of
    | ovrld:eqExpr(_, directCallExpr(_, a)) -> a
    | directCallExpr(_, a) -> a
    | _ -> error("Invalid forms reported via errors attribute")
    end;

  local lhsAssignment :: Maybe<Expr> =
    case expr of
    | ovrld:eqExpr(declRefExpr(n), directCallExpr(_, _)) -> just(ableC_Expr{$Name{n}})
    | ovrld:eqExpr(_, directCallExpr(_, _)) -> just(ableC_Expr{*__ret})
    | _ -> nothing()
    end;
  local preAssignment :: Maybe<Stmt> =
    case expr of
    | ovrld:eqExpr(declRefExpr(_), directCallExpr(_, _)) -> nothing()
    | ovrld:eqExpr(_, directCallExpr(_, _)) -> just(ableC_Stmt {
          typeof($Expr{lhs.fromJust})* __ret = &($Expr{lhs.fromJust});
        })
    | _ -> nothing()
    end;
  local rhsPointer :: Maybe<Expr> =
    case expr of
    | ovrld:eqExpr(declRefExpr(n), directCallExpr(_, _)) ->
        just(referenceAVariable(n.name, top.env))
    | ovrld:eqExpr(_, directCallExpr(_, _)) -> just(ableC_Expr{__ret})
    | _ -> nothing()
    end;

  top.workstlrParFastClone =
    if annts.bySystem.isJust
    then fwrd.workstlrParFastClone -- Regular result of propagate
    -- Otherwise this is a Workstlr-style spawn
    else if anyAnnotations
    then warnStmt([err(expr.location, "Annotations not currently supported on workstlr-style spawns.")])
    else if !validForm
    then warnStmt([err(expr.location, "This type of expression is not currently supported for workstlr-style spawns: " ++ hackUnparse(expr))])
    else ableC_Stmt {{
        $Stmt{saveVariables(top.env)}

        __closure->joinCounter++;
        __closure->state = $intLiteralExpr{top.workstlrParInitState};
        workstlr_push_head(workstlr_thread_deque, __closure);

        $Stmt{
          if lhs.isJust
          then ableC_Stmt { 
              $Stmt{if preAssignment.isJust then preAssignment.fromJust else nullStmt()}
              $Expr{lhsAssignment.fromJust} = $name{s"__${fname}_fast"}
                  ($Exprs{appendExprs(args,
                      consExpr(
                        rhsPointer.fromJust,
                        consExpr(
                          ableC_Expr { (struct workstlr_closure*) __closure },
                          nilExpr()
                        )
                      )
                    )
                  });
              
              $Stmt{case (decorate lhs.fromJust with {env=top.env;
                        controlStmtContext=initialControlStmtContext;}) of
                    | ableC_Expr {$Name{n}} -> saveAVariable(n.name, top.env)
                    | _ -> nullStmt()
                    end}
            }
          else ableC_Stmt { 
              $name{s"__${fname}_fast"}($Exprs{appendExprs(args,
                    consExpr(ableC_Expr{(struct workstlr_closure*) __closure},
                      nilExpr()))});
            }
        }

        int __counter = --(__closure->joinCounter);

        // If this closure was stolen
        if (workstlr_verify_pop_head(workstlr_thread_deque, __closure) == 0) {
          if (__counter < 0) {
            // Put it on the deque so that it will be worked on
            workstlr_push_head(workstlr_thread_deque, __closure);
          }
          longjmp(workstlr_jmp_buf, 1); // Return to the scheduler
        }
      }};
  top.workstlrParSlowClone =
    if annts.bySystem.isJust
    then fwrd.workstlrParSlowClone -- Regular result of propagate
    -- Otherwise this is a Workstlr-style spawn
    else if anyAnnotations
    then warnStmt([err(expr.location, "Annotations not currently supported on workstlr-style spawns.")])
    else if !validForm
    then warnStmt([err(expr.location, "This type of expression is not currently supported for workstlr-style spawns.")])
    else ableC_Stmt {{
        $Stmt{saveVariables(top.env)}

        __closure->joinCounter++;
        __closure->state = $intLiteralExpr{top.workstlrParInitState};
        workstlr_push_head(workstlr_thread_deque, __closure);

        $Stmt{
          if lhs.isJust
          then ableC_Stmt { 
              $Stmt{if preAssignment.isJust then preAssignment.fromJust else nullStmt()}
              $Expr{lhsAssignment.fromJust} = $name{s"__${fname}_fast"}
                ($Exprs{appendExprs(args,
                  consExpr(
                    rhsPointer.fromJust,
                    consExpr(
                      ableC_Expr { (struct workstlr_closure*) __closure },
                      nilExpr()
                    )
                  )
                )
              });
              
              $Stmt{case (decorate lhs.fromJust with {env=top.env;
                        controlStmtContext=initialControlStmtContext;}) of
                    | ableC_Expr {$Name{n}} -> saveAVariable(n.name, top.env)
                    | _ -> nullStmt()
                    end}
            }
          else ableC_Stmt { 
              $name{s"__${fname}_fast"}($Exprs{appendExprs(args,
                    consExpr(ableC_Expr{(struct workstlr_closure*) __closure},
                      nilExpr()))});
            }
        }

        int __counter = --(__closure->joinCounter);

        // If this closure was stolen
        if (workstlr_verify_pop_head(workstlr_thread_deque, __closure) == 0) {
          if (__counter < 0) {
            // Put it on the deque so that it will be worked on
            workstlr_push_head(workstlr_thread_deque, __closure);
          }
          return; // Slow clone can return directly to the scheduler
        }
            
        if (0) {
          $name{s"__${top.workstlrParFuncName}_slow_state${toString(top.workstlrParInitState)}"}: ;
          $Stmt{loadVariables(top.env)}
        }
      }};
}
