grammar edu:umn:cs:melt:exts:ableC:parallel:impl:workstlr:func;

abstract production workstlrParFunctionConverter
top::Decl ::= func::ParallelFunctionDecl
{
  top.pp = func.pp;

  -- TODO: Locations
  local localErrors :: [Message] =
    case func of
    | parallelFunctionProto(storage, fnquals, bt, mt, fname, attrs) ->
        fnquals.errors ++ bt.errors ++ mt.errors ++
        case storage, fnquals, attrs of
        | nilStorageClass(), nilSpecialSpecifier(), nilAttribute() -> []
        -- There's a comment about not allowing these in the ableC-cilk extension
        | _, _, _ -> [err(fname.location, s"Parallel Workstlr functions should not have storage classes, qualifiers, or attributes on them")]
        end
    | parallelFunctionDecl(storage, fnquals, bt, mt, fname, attrs, dcls, body) ->
        fnquals.errors ++ bt.errors ++ mt.errors ++ dcls.errors ++
        -- We don't add body.errors because spawn/sync behave differently in
        -- a parallel cilk function and would otherwise result in errors
        case storage, fnquals, attrs of
        | nilStorageClass(), nilSpecialSpecifier(), nilAttribute() -> []
        | _, _, _ -> [err(fname.location, s"Parallel Workstlr functions should not have storage classes, qualifiers, or attributes on them")]
        end
    end
    ++
    (if fname.name == "main"
    then [err(fname.location, "Cannot declare main() to be a Parallel Workstlr function")]
    else [])
    ++
    (case mty of
    | functionTypeExprWithArgs(_, _, true, _) -> [err(fname.location, "Parallel Workstlr function cannot be variadic")]
    | _ -> []
    end);
    -- TODO: Can we detect variable shadowing and issue an error

  local fname :: Name =
    case func of
    | parallelFunctionProto(_, _, _, _, n, _) -> n
    | parallelFunctionDecl(_, _, _, _, n, _, _, _) -> n
    end;

  local cleanName :: String = s"__${fname.name}_";

  local bty :: BaseTypeExpr =
    case func of
    | parallelFunctionProto(_, _, bty, _, _, _) -> new(bty)
    | parallelFunctionDecl(_, _, bty, _, _, _, _, _) -> new(bty)
    end;
  bty.controlStmtContext = top.controlStmtContext;
  bty.env = top.env;
  bty.givenRefId = nothing();

  local mty :: TypeModifierExpr =
    case func of
    | parallelFunctionProto(_, _, _, mty, _, _) -> new(mty)
    | parallelFunctionDecl(_, _, _, mty, _, _, _, _) -> new(mty)
    end;
  mty.baseType = bty.typerep;
  mty.typeModifierIn = bty.typeModifier;
  mty.env = openScopeEnv(addEnv(bty.defs, top.env));
  mty.controlStmtContext = top.controlStmtContext;

  local ds :: Decls =
    case func of
    | parallelFunctionProto(_, _, _, _, _, _) -> nilDecl()
    | parallelFunctionDecl(_, _, _, _, _, _, d, _) -> d
    end;
  ds.env = addEnv(mty.defs ++ args.functionDefs, mty.env);
  ds.isTopLevel = false;
  ds.controlStmtContext = top.controlStmtContext;

  local retMty :: TypeModifierExpr =
    case mty of
    | functionTypeExprWithArgs(r, _, _, _) -> r
    | functionTypeExprWithoutArgs(r, _, _) -> r
    | _ -> error("Invalid forms reported via errors attribute")
    end;

  -- Parameters for the function
  local args :: Decorated Parameters =
    case mty of
    | functionTypeExprWithArgs(_, args, _, _) -> args
    | functionTypeExprWithoutArgs(_, _, _) -> (decorate nilParameters() with {env=top.env; 
        position=0; controlStmtContext=initialControlStmtContext;})
    | _ -> error("Invalid forms reported via errors attribute")
    end;

  -- Parameters for the fast clone (those of the function + ret pointer and parent pointer)
  local fastParams :: Parameters =
    appendParameters(
      new(args),
      let parentParam :: Parameters =
        consParameters(
          parameterDecl( -- struct workstlr_closure* __parent
            nilStorageClass(),
            ableC_BaseTypeExpr { struct workstlr_closure },
            pointerTypeExpr(nilQualifier(), baseTypeExpr()),
            justName(name("__parent", location=fname.location)),
            nilAttribute()
          ),
          nilParameters()
        )
      in 
      if retVoid then parentParam
      else 
      consParameters(
        parameterDecl( -- T* __ret
          nilStorageClass(), new(bty), pointerTypeExpr(nilQualifier(), retMty),
            justName(name("__ret", location=fname.location)), nilAttribute()
        ),
        parentParam
      )
      end
    );

  local functionDecls :: [Decorated Decl] = 
    case func of
    | parallelFunctionDecl(_, _, bty, mty, _, _, ds, bd) -> 
        bty.functionDecls ++ mty.functionDecls ++ ds.functionDecls ++
        bd.functionDecls
    | _ -> error("Invalid forms reported via errors attribute")
    end;

  top.functionDecls := [];

  local origBody :: Stmt =
    case func of
    | parallelFunctionDecl(_, _, _, _, _, _, _, b) -> new(b)
    | _ -> error("Invalid forms reported via errors attribute")
    end;
  origBody.controlStmtContext = bodyCscx;
  origBody.env = bodyEnv;

  local body :: Stmt =
    seqStmt(foldr(
      \decl::Decorated Decl stmt::Stmt ->
        seqStmt(declStmt(decl.host), stmt),
      nullStmt(), functionDecls),
    dropFunctionDecls(origBody.workstlrParForConverted));
  body.controlStmtContext = bodyCscx;
  body.env = bodyEnv;

  body.workstlrParFuncName = fname.name;
  body.workstlrParInitState = 1;

  -- collect all fields with the same scopeId into a list and pair with the scopeId
  local frameDeclsByScopes :: [Pair<String [StructItem]>] =
    collectFrameDecls(args.cilkFrameDeclsScopes ++ body.cilkFrameDeclsScopes, []);
  local frameFields :: [StructItem] =
    map(makeFrameDeclsScope, frameDeclsByScopes);

  local retType :: Type = (decorate retMty with {baseType=bty.typerep; typeModifierIn=baseTypeExpr(); 
      env=top.env; controlStmtContext=initialControlStmtContext;}).typerep;
  local retVoid :: Boolean =
    case retType of builtinType(_, voidType()) -> true | _ -> false end;

  local closureFrame :: StructItemList = foldr(consStructItem, nilStructItem(), frameFields);
  local closureOutpt :: StructItemList =
    consStructItem(
      structItem( -- parent
        nilAttribute(),
        ableC_BaseTypeExpr { struct workstlr_closure },
        consStructDeclarator(
          structField(
            name("parent", location=fname.location),
            pointerTypeExpr(nilQualifier(), baseTypeExpr()),
            nilAttribute()
          ),
          nilStructDeclarator()
        )
      ),
      if retVoid
      then nilStructItem()
      else
        consStructItem(
          structItem( -- return pointer
            nilAttribute(),
            retType.baseTypeExpr,
            consStructDeclarator(
              structField(
                name("ret", location=fname.location),
                pointerTypeExpr(nilQualifier(), retType.typeModifierExpr),
                nilAttribute()
              ),
              nilStructDeclarator()
            )
          ),
          nilStructItem()
        )
    );

  local bodyEnv :: Decorated Env =
    addEnv(ds.defs ++ origBody.functionDefs, ds.env);
  local bodyCscx :: ControlStmtContext =
    controlStmtContext(just(retType), false, false, tm:add(body.labelDefs, tm:empty()));

  forwards to
    case func of
    | parallelFunctionProto(_, _, _, _, _, _) ->
      if !null(localErrors)
      then warnDecl(localErrors)
      else decls(
        foldDecl([
          ableC_Decl { struct $name{cleanName ++ "closure"}; },
          ableC_Decl { void $name{cleanName ++ "slow"}(void*); },
          ableC_Decl { $directTypeExpr{retType} $name{cleanName++"fast"}($Parameters{fastParams}); },
          ableC_Decl { $directTypeExpr{retType} $Name{fname}($Parameters{new(args)}) ; } -- We produce this so that the name exists
        ]))
    | parallelFunctionDecl(_, _, _, _, _, _, _, _) ->
      if !null(localErrors)
      then warnDecl(localErrors)
      else decls(
        foldDecl([
          ableC_Decl {  struct $name{cleanName ++ "closure"} {
                          void (*func)(void*);
                          _Atomic int joinCounter;
                          int state;
                          struct $name{cleanName ++ "closure_frame"} { $StructItemList{closureFrame} } frame;
                          struct $name{cleanName ++ "closure_output"} { $StructItemList{closureOutpt} } output;
                        }; },
          ableC_Decl { $directTypeExpr{retType} $name{cleanName++"fast"}($Parameters{fastParams}); },
          ableC_Decl {  void $name{cleanName ++ "slow"}(void* in) {
                          struct $name{cleanName ++ "closure"}* __closure = in;
                        
                          $Stmt{declareArgs(args)}

                          $Stmt{if retVoid then nullStmt() else ableC_Stmt {$directTypeExpr{retType} __retVal; }}

                          switch (__closure->state) {
                            $Stmt{foldStmt(map(\i::Integer -> ableC_Stmt { 
                                case $intLiteralExpr{i}:
                                  goto $name{cleanName ++ s"slow_state${toString(i)}"}; },
                              range(0, body.workstlrParNeedStates+1)))}
                            default: exit(100);
                          }
                          
                          $name{cleanName ++ "slow_state0"}: ;
                          $Stmt{loadVariables(bodyEnv)}

                          $Stmt{body.workstlrParSlowClone}

                          $Stmt{labelStmt(name(cleanName ++ "slow_return", location=builtinLoc(MODULE_NAME)), nullStmt())}
                          $Stmt{if retVoid then nullStmt() else ableC_Stmt {
                            *(__closure->output.ret) = __retVal; } }
                          if (--(__closure->output.parent->joinCounter) < 0) {
                            workstlr_push_head(workstlr_thread_deque, __closure->output.parent);
                          }
                          free(__closure);
                          return; // to the scheduler
                        } },
          ableC_Decl {  $directTypeExpr{retType} $name{cleanName++"fast"}($Parameters{fastParams}) {
                          struct $name{cleanName ++ "closure"}* __closure = malloc(sizeof(struct $name{cleanName ++ "closure"}));
                          __closure->func = $name{cleanName ++ "slow"};
                          __closure->joinCounter = 0;
                          __closure->state = 0;
                          $Stmt{if retVoid then nullStmt() else ableC_Stmt { __closure->output.ret = __ret;} }
                          __closure->output.parent = __parent;

                          $Stmt{if retVoid then nullStmt() else ableC_Stmt {$directTypeExpr{retType} __retVal; }}

                          $Stmt{body.workstlrParFastClone}

                          $Stmt{labelStmt(name(cleanName ++ "fast_return", location=builtinLoc(MODULE_NAME)), nullStmt())}
                          free(__closure);
                          $Stmt{if retVoid then nullStmt() else ableC_Stmt {return __retVal;} }
                        } },
          ableC_Decl { $directTypeExpr{retType} $Name{fname}($Parameters{new(args)}) { // We produce this so that the name exists
                          fprintf(stderr, $stringLiteralExpr{s"Directly called ${fname.name} rather than invoking it through a workstlr-spawn\n"}); 
                          exit(25); 
                        } 
          }]))
    | _ -> error("WorkstlrFunctionDefinition produced unknown production in AST")
    end;
}

function inputStructItems
StructItemList ::= p::Decorated Parameters
{
  return
    case p of
    | nilParameters() -> nilStructItem()
    | consParameters(parameterDecl(_, bt, tm, justName(n), attrs), tl) ->
        consStructItem(
          structItem(nilAttribute(), bt,
            consStructDeclarator(
              structField(n, tm, attrs),
              nilStructDeclarator()
            )
          ),
          inputStructItems(tl)
        )
    | _ -> error("Other forms not permitted by checks in calling locations")
    end;
}

function declareArgs
Stmt ::= p::Decorated Parameters
{
  return
    case p of
    | nilParameters() -> nullStmt()
    | consParameters(parameterDecl(sc, bt, tm, justName(n), attrs), tl) ->
        seqStmt(
          declStmt(
            variableDecls(sc, attrs, bt, 
              consDeclarator(declarator(n, tm, nilAttribute(), nothingInitializer()),
                nilDeclarator()
              )
            )
          ),
          declareArgs(tl)
        )
    | _ -> error("Other forms not permitted by checks in calling locations")
    end;
}

function saveVariables
Stmt ::= env::Decorated Env
{
  -- get all name/scopeIds pairs except those at global scope
  local frameVars :: [Pair<String String>] =
    foldr(append, [], map(tm:toList, take(length(env.scopeIds)-1, env.scopeIds)));

	-- TODO: save only live & dirty variables
  return foldStmt(map(saveVariable, frameVars));
}

function referenceAVariable
Expr ::= n::String env::Decorated Env
{
  local frameVars :: [Pair<String String>] =
    foldr(append, [], map(tm:toList, take(length(env.scopeIds)-1, env.scopeIds)));
  local frameVarNamed :: [Pair<String String>] =
    filter(\p::Pair<String String> -> p.fst == n, frameVars);

  return
    case frameVarNamed of
    | pair(nm, scopeId) :: [] -> 
        ableC_Expr { &(__closure->frame.$name{"scope" ++ scopeId}.$name{nm}) }
    | _ -> ableC_Expr { &$name{n} }
    end;
}

function saveAVariable
Stmt ::= n::String env::Decorated Env
{
  local frameVars :: [Pair<String String>] =
    foldr(append, [], map(tm:toList, take(length(env.scopeIds)-1, env.scopeIds)));
  local frameVarsNamed :: [Pair<String String>] =
    filter(\p::Pair<String String> -> p.fst == n, frameVars);

  return
    case frameVarsNamed of
    | v :: [] -> saveVariable(v)
    | _ -> nullStmt()
    end;
}

function saveVariable
Stmt ::= frameVar::Pair<String String>
{
  local n :: String = fst(frameVar);
  local scopeId :: String = snd(frameVar);

  return
    -- Don't need to save certain internally generated variables
    if n == "__closure" || n == "__ret" || n == "__parent" || n == "__retVal"
		then nullStmt()
    else ableC_Stmt { __closure->frame.$name{"scope" ++ scopeId}.$name{n} = $name{n}; };
}

function loadVariables
Stmt ::= env::Decorated Env
{
  -- get all name/scopeIds pairs except those at global scope
  local frameVars :: [Pair<String String>] =
    foldr(append, [], map(tm:toList, take(length(env.scopeIds)-1, env.scopeIds)));

  return foldStmt(map(\p::Pair<String String> -> loadVariable(p, env), frameVars));
}

function loadVariable
Stmt ::= frameVar::Pair<String String> env::Decorated Env
{
  local n :: String = fst(frameVar);
  local scopeId :: String = snd(frameVar);

  local varType :: BaseTypeExpr =
    directTypeExpr((decorate
      declRefExpr(name(n, location=builtinLoc(MODULE_NAME)),
        location=builtinLoc(MODULE_NAME))
      with {env=env; controlStmtContext=initialControlStmtContext;}).typerep);

  return
    if n == "__closure" || n == "__ret" || n == "__parent" || n == "__retVal"
    then nullStmt()
    else ableC_Stmt { $name{n} = 
        __closure->frame.$name{"scope" ++ scopeId}.$name{n}; };
}

abstract production dropFunctionDecls
top::Stmt ::= bd::Stmt
{
  top.functionDecls := [];
  forwards to bd;
}
