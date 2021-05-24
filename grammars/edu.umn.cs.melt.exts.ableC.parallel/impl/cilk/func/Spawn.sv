grammar edu:umn:cs:melt:exts:ableC:parallel:impl:cilk:func;

aspect production spawnTask
top::Stmt ::= expr::Expr annts::SpawnAnnotations
{
  -- A Cilk spawn does not have a by ...; annotation and also shouldn't have
  -- any other annotations on it

  local fwrd :: Stmt = new(top.forward);
  fwrd.cilkParFuncName = top.cilkParFuncName;
  fwrd.cilkParInitState = top.cilkParInitState;
  fwrd.controlStmtContext = initialControlStmtContext;
  fwrd.env = top.env;

  -- Actually not sure if this is correct behavior for non-Cilk spawn, since
  -- generally the expr will be lifted out of the Cilk function
  top.cilkParNeedStates = if annts.bySystem.isJust 
    then fwrd.cilkParNeedStates else 1;
  
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

  top.cilkParFastClone =
    if annts.bySystem.isJust
    then fwrd.cilkParFastClone -- Regular result of propagate
    -- Otherwise this is a Cilk-style spawn
    else if anyAnnotations
    then warnStmt([err(expr.location, "Annotations not currently supported on cilk-style spawns.")])
    else if !validForm
    then warnStmt([err(expr.location, "This type of expression is not currently supported for cilk-style spawns: " ++ hackUnparse(expr))])
    else ableC_Stmt {{
        $Stmt{saveVariables(top.env)}

        __closure->joinCounter++;
        __closure->state = $intLiteralExpr{top.cilkParInitState};
        cilk_push_head(cilk_thread_deque, __closure);

        $Stmt{
          if lhs.isJust
          then ableC_Stmt { 
              $Stmt{if preAssignment.isJust then preAssignment.fromJust else nullStmt()}
              $Expr{lhsAssignment.fromJust} = $name{s"__${fname}_fast"}
                  ($Exprs{appendExprs(args,
                      consExpr(
                        rhsPointer.fromJust,
                        consExpr(
                          ableC_Expr { (struct cilk_closure*) __closure },
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
                    consExpr(ableC_Expr{(struct cilk_closure*) __closure},
                      nilExpr()))});
            }
        }

        int __counter = --(__closure->joinCounter);

        // If this closure was stolen
        if (cilk_verify_pop_head(cilk_thread_deque, __closure) == 0) {
          if (__counter < 0) {
            // Put it on the deque so that it will be worked on
            cilk_push_head(cilk_thread_deque, __closure);
          }
          longjmp(cilk_jmp_buf, 1); // Return to the scheduler
        }
      }};
  top.cilkParSlowClone =
    if annts.bySystem.isJust
    then fwrd.cilkParSlowClone -- Regular result of propagate
    -- Otherwise this is a Cilk-style spawn
    else if anyAnnotations
    then warnStmt([err(expr.location, "Annotations not currently supported on cilk-style spawns.")])
    else if !validForm
    then warnStmt([err(expr.location, "This type of expression is not currently supported for cilk-style spawns.")])
    else ableC_Stmt {{
        $Stmt{saveVariables(top.env)}

        __closure->joinCounter++;
        __closure->state = $intLiteralExpr{top.cilkParInitState};
        cilk_push_head(cilk_thread_deque, __closure);

        $Stmt{
          if lhs.isJust
          then ableC_Stmt { 
              $Stmt{if preAssignment.isJust then preAssignment.fromJust else nullStmt()}
              $Expr{lhsAssignment.fromJust} = $name{s"__${fname}_fast"}
                ($Exprs{appendExprs(args,
                  consExpr(
                    rhsPointer.fromJust,
                    consExpr(
                      ableC_Expr { (struct cilk_closure*) __closure },
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
                    consExpr(ableC_Expr{(struct cilk_closure*) __closure},
                      nilExpr()))});
            }
        }

        int __counter = --(__closure->joinCounter);

        // If this closure was stolen
        if (cilk_verify_pop_head(cilk_thread_deque, __closure) == 0) {
          if (__counter < 0) {
            // Put it on the deque so that it will be worked on
            cilk_push_head(cilk_thread_deque, __closure);
          }
          return; // Slow clone can return directly to the scheduler
        }
            
        if (0) {
          $name{s"__${top.cilkParFuncName}_slow_state${toString(top.cilkParInitState)}"}: ;
          $Stmt{loadVariables(top.env)}
        }
      }};
}
