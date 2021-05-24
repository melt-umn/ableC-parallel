grammar edu:umn:cs:melt:exts:ableC:parallel:impl:thrdpool;

abstract production thrdpoolParallelSystem
top::ParallelSystem ::= 
{
  top.parName = "thrdpool";

  top.fSpawn = thrdpoolSpawn;
  top.fFor = thrdpoolFor;
  top.newProd = just(\a::Exprs l::Location -> thrdpoolParallelNew(a, location=l));
  top.deleteProd = just(thrdpoolParallelDelete);
}

aspect production systemNumbering
top::SystemNumbering ::=
{
  systems <- [thrdpoolParallelSystem()];
}

abstract production thrdpoolSpawn
top::Stmt ::= e::Expr loc::Location annts::SpawnAnnotations
{
  top.pp = ppConcat([text("spawn"), e.pp, semi()]);
  top.functionDefs := [];
  top.labelDefs := [];

  local sys :: Expr = annts.bySystem.fromJust;
  sys.env = top.env;
  sys.controlStmtContext = initialControlStmtContext;

  local threads :: [Expr] = annts.asThreads;
  local groups :: [Expr] = annts.inGroups;

  local privateVars :: [Name] = nub(annts.privates);
  local publicVars  :: [Name] = nub(annts.publics);
  local globalVars  :: [Name] = nub(annts.globals);

  local localErrors :: [Message] = e.errors ++ annts.errors ++ missingVars;

  local liftedName :: String =
    s"__lifted_thrd_parallel_${substitute(":", "_", substitute(".", "_", loc.unparse))}";

  local freeVars :: [Name] = nub(e.freeVariables);

  local freePublic  :: [Name] = intersect(freeVars, publicVars);
  local freePrivate :: [Name] = intersect(freeVars, privateVars);
  local freeGlobal  :: [Name] = intersect(freeVars, globalVars);

  -- It's an error if any of the elements in freeNeither is NOT a global
  -- variable
  local globalenvr :: Decorated Env = globalEnv(top.env);
  local missingVars :: [Message] =
    flatMap(
      \n :: Name ->
        if contains(n, freePublic) || contains(n, freePrivate)
        then []
        else if contains(n, freeGlobal)
        then
          if null((decorate n with {env=globalenvr;}).valueLookupCheck)
          then []
          else [err(loc, "Variable '${n.name}' used in spawn is given a global annotation but is not a global variable")]
        else [err(loc, s"Variable '${n.name}' used in spawn not given a public/private/global annotation")],
      freeVars);

  local publicVarTypes :: [Type] = map(
    \n::Name ->
      pointerType(
        nilQualifier(),
        (decorate n with {env=top.env;}).valueItem.typerep
      ),
    freePublic);
  local privateVarTypes :: [Type] = map(
    \n::Name ->
      (decorate n with {env=top.env;}).valueItem.typerep,
    freePrivate);

  local structItemNames :: [Name] =
    freePublic
    ++ freePrivate
    ++ map(\i::Integer -> name(s"__thread_${toString(i)}", location=loc),
        range(0, length(threads)))
    ++ map(\i::Integer -> name(s"__group_${toString(i)}", location=loc),
        range(0, length(groups)));
  local structItemTypes :: [Type] =
    publicVarTypes
    ++ privateVarTypes
    ++ map(
        \e::Expr -> 
          getPointerType(
            (decorate e with {env=top.env;
                      controlStmtContext = initialControlStmtContext;}).typerep
          ), 
        threads ++ groups); 
  local structItemInits :: [Expr] =
    map(\n::Name -> ableC_Expr{&$Name{n}}, freePublic)
    ++ map(\n::Name -> ableC_Expr{$Name{n}}, freePrivate)
    ++ map(\e::Expr -> 
      getReference(decorate e with {env=top.env;
                                controlStmtContext=initialControlStmtContext;}),
      threads ++ groups);

  local structItems :: [StructItem] =
    map(\p::Pair<Name Type> -> 
        structItem(nilAttribute(), p.snd.baseTypeExpr, 
          consStructDeclarator(
            structField(p.fst, p.snd.typeModifierExpr, nilAttribute()), 
            nilStructDeclarator()
          )
        ),
      zipWith(pair, structItemNames, structItemTypes));
  local struct :: StructDecl =
    structDecl(
      consAttribute(
        gccAttribute(
          consAttrib(
            appliedAttrib(
              attribName(name("refId", location=loc)), 
              consExpr(
                mkStringConst("edu:umn:cs:melt:exts:ableC:parallel:impl:thrdpool:input" ++ liftedName, loc),
                nilExpr()
              )
            ),
            nilAttrib()
          )
        ), 
        nilAttribute()),
      justName(name(liftedName ++ "_struct", location=loc)),
      foldStructItem(structItems), location=loc);
  local structDcl :: Decl = 
    typeExprDecl(nilAttribute(), structTypeExpr(nilQualifier(), struct));

  structDcl.controlStmtContext = initialControlStmtContext;
  structDcl.isTopLevel = true;
  structDcl.env = globalEnv(top.env);

  local globalEnvStruct :: Decorated Env = 
    addEnv(
      structDcl.defs,
      globalEnv(top.env)
    );
  local transformedEnv :: Decorated Env =
    addEnv(
      valueDef("args", 
        declaratorValueItem(
          decorate declarator(
            name("args", location=loc),
            pointerTypeExpr(nilQualifier(), baseTypeExpr()),
            nilAttribute(),
            nothingInitializer()
          ) with {
            typeModifierIn = baseTypeExpr();
            controlStmtContext = initialControlStmtContext;
            isTypedef = false;
            isTopLevel = false;
            givenStorageClasses = nilStorageClass();
            givenAttributes = nilAttribute();
            baseType =
              extType(nilQualifier(),
                refIdExtType(
                  structSEU(),
                  just(liftedName ++ "_struct"),
                  "edu:umn:cs:melt:exts:ableC:parallel:impl:thrdpool:input" ++ liftedName
                )
              );
            env = globalEnvStruct;
          }
        )
      )
      :: 
      map(
        \n::Name -> 
          valueDef(n.name,
            declaratorValueItem(
              decorate declarator(
                n,
                baseTypeExpr(),
                nilAttribute(),
                nothingInitializer()
              ) with {
                typeModifierIn = baseTypeExpr();
                controlStmtContext = initialControlStmtContext;
                isTypedef = false;
                isTopLevel = false;
                givenStorageClasses = nilStorageClass();
                givenAttributes = nilAttribute();
                baseType = extType(nilQualifier(), fakePublicForLift());
                env = globalEnvStruct;
              }
            )
          ),
        freePublic
      )
      ++
      map(
        \n::Name ->
          valueDef(n.name,
            declaratorValueItem(
              decorate declarator(
                n,
                baseTypeExpr(),
                nilAttribute(),
                nothingInitializer()
              ) with {
                typeModifierIn = baseTypeExpr();
                controlStmtContext = initialControlStmtContext;
                isTypedef = false;
                isTopLevel = false;
                givenStorageClasses = nilStorageClass();
                givenAttributes = nilAttribute();
                baseType = extType(nilQualifier(), fakePrivateForLift());
                env = globalEnvStruct;
              }
            )
          ),
        freePrivate
      ),
      openScopeEnv(
        globalEnvStruct
      )
    );

  local transformedExpr :: Expr =
    (decorate e with {env=transformedEnv;
                    controlStmtContext=initialControlStmtContext;}).forLift;

  local functionDecl :: Decl =
    ableC_Decl {
      static void $name{liftedName ++ "_function"}(void* ptr) {
        struct $name{liftedName ++ "_struct"}* args = ptr;

        $Stmt{foldStmt(
          map(
            \p::Pair<Integer Expr> -> 
              case decorate p.snd with {env=top.env;
                    controlStmtContext=initialControlStmtContext;}.typerep of
              | extType(_, threadType(s)) -> 
                  (decorate s with {env=transformedEnv; 
                    threads=[ableC_Expr{args->$name{s"__thread_${toString(p.fst)}"}}];
                  }).threadThrdOps
              | _ -> error("Other forms reported via errors attribute")
              end,
            zipWith(pair, range(0, length(threads)), threads)
          ) 
          ++ 
          map(
            \p::Pair<Integer Expr> -> 
              case decorate p.snd with {env=top.env;
                controlStmtContext=initialControlStmtContext;}.typerep of
              | extType(_, groupType(s)) ->
                  (decorate s with {env=transformedEnv;
                    groups=[ableC_Expr{args->$name{s"__group_${toString(p.fst)}"}}];
                  }).groupThrdOps
              | _ -> error("Other forms reported via errors attribute")
              end,
            zipWith(pair, range(0, length(groups)), groups)
          )
        )}

        {
          $Expr{transformedExpr};
        }

        $Stmt{foldStmt(
          map(
            \p::Pair<Integer Expr> -> 
              case decorate p.snd with {env=top.env;
                controlStmtContext=initialControlStmtContext;}.typerep of
              | extType(_, threadType(s)) -> 
                  (decorate s with {env=transformedEnv;
                    threads=[ableC_Expr{args->$name{s"__thread_${toString(p.fst)}"}}];
                  }).threadPostOps
              | _ -> error("Other forms reported via errors attribute")
              end,
            zipWith(pair, range(0, length(threads)), threads)
          ) 
          ++ 
          map(
            \p::Pair<Integer Expr> -> 
              case decorate p.snd with {env=top.env;
                controlStmtContext=initialControlStmtContext;}.typerep of
              | extType(_, groupType(s)) ->
                  (decorate s with {env=transformedEnv;
                    groups=[ableC_Expr{args->$name{s"__group_${toString(p.fst)}"}}];
                  }).groupPostOps
              | _ -> error("Other forms reported via errors attribute")
              end,
            zipWith(pair, range(0, length(groups)), groups)
          )
        )}

        free(ptr);

        struct __thrdpool_work_item* _work = 
          (struct __thrdpool_work_item*) __ableC_thread_tcb->thread_info;

        __thrdpool_please_free = _work->contents.resume.stack;

        free(_work);
        __ableC_thread_tcb = (void*) 0;

        longjmp(__thrdpool_return, 1);

        fprintf(stderr, "Internal Error: Thread pool longjmp failed");
        exit(-1);
      }
    };

  local fwrdStmt :: Stmt =
    ableC_Stmt {
      {
        struct $name{liftedName ++ "_struct"}* args = 
          malloc(sizeof(struct $name{liftedName ++ "_struct"}));
        $Stmt{foldStmt(map(
            \p::Pair<Name Expr> ->
              ableC_Stmt {
                args->$Name{p.fst} = $Expr{p.snd};
              },
            zipWith(pair, structItemNames, structItemInits)))}
       
        $Stmt{foldStmt(
          map(
            \p::Pair<Integer Expr> -> 
              case decorate p.snd with {env=top.env;
                controlStmtContext=initialControlStmtContext;}.typerep of
              | extType(_, threadType(s)) -> 
                  (decorate s with {env=transformedEnv;
                    threads=[ableC_Expr{args->$name{s"__thread_${toString(p.fst)}"}}];
                  }).threadBefrOps
              | _ -> error("Other forms reported via errors attribute")
              end,
            zipWith(pair, range(0, length(threads)), threads)
          ) 
          ++ 
          map(
            \p::Pair<Integer Expr> -> 
              case decorate p.snd with {env=top.env;
                controlStmtContext=initialControlStmtContext;}.typerep of
              | extType(_, groupType(s)) ->
                  (decorate s with {env=transformedEnv;
                    groups=[ableC_Expr{args->$name{s"__group_${toString(p.fst)}"}}];
                  }).groupBefrOps
              | _ -> error("Other forms reported via errors attribute")
              end,
            zipWith(pair, range(0, length(groups)), groups)
          )
        )}

        struct __thrdpool_work_item* _work = malloc(sizeof(struct __thrdpool_work_item));
        _work->started = 0;
        _work->next = (void*) 0;
        _work->contents.start.f = $name{liftedName ++ "_function"};
        _work->contents.start.args = args;
        _work->contents.start.parent = __ableC_thread_tcb;

        struct __ableC_system_info* _sys_info = 
          (struct __ableC_system_info*) $Expr{sys};
        struct __thrdpool_system_info* _pool = 
          (struct __thrdpool_system_info*) _sys_info->system_data;

        checked_pthread_mutex_lock(&(_pool->lk));

        if (_pool->work_head == (void*) 0) {
          _pool->work_head = _work;
          _pool->work_tail = _work;
        } else {
          _pool->work_tail->next = _work;
          _pool->work_tail = _work;
        }

        checked_pthread_cond_signal(&(_pool->cv));
        checked_pthread_mutex_unlock(&(_pool->lk));
      }
    };

  forwards to
    if !null(localErrors)
    then warnStmt(localErrors)
    else
      injectGlobalDeclsStmt(
        consDecl(structDcl, consDecl(functionDecl, nilDecl())),
        fwrdStmt
      );
}

abstract production thrdpoolFor
top::Stmt ::= loop::Stmt loc::Location annts::ParallelAnnotations
{
  top.pp = ppConcat([text("parallel"), top.pp]);
  top.functionDefs := loop.functionDefs;
  top.labelDefs := [];

  local loopInfo :: Pair<Pair<BaseTypeExpr Name> Pair<Expr Stmt>>= 
    case loop of
    | ableC_Stmt { for($BaseTypeExpr{bt} $Name{i1} = host::(0); host::$Name{_} host::< $Expr{bound}; host::$Name{_} host::++) $Stmt{bd} } 
      -> pair(pair(bt, i1), pair(bound, bd))
    | _ -> error("Other forms reported as errors by invocation in ableC-parallel")
    end;

  local varType :: BaseTypeExpr = loopInfo.fst.fst;
  local var :: Name = loopInfo.fst.snd;
  local bound :: Expr = loopInfo.snd.fst;
  local loopBody :: Stmt = loopInfo.snd.snd;

  local spawnAnnts :: SpawnAnnotations = 
    consSpawnAnnotations(
      spawnPrivateAnnotation(name("_thread_num", location=loc) :: [], location=loc),
      consSpawnAnnotations(
        spawnPrivateAnnotation(name("_n_iters_per_thread", location=loc) :: [], location=loc),
        consSpawnAnnotations(
          spawnPrivateAnnotation(name("_n_iters_extra", location=loc) :: [], location=loc),
          parallelToSpawnAnnts(annts)
        )
      )
    );

  local spawnStmt :: Stmt =
    thrdpoolSpawn(ableC_Expr {
        ({
          const $BaseTypeExpr{varType} _first_iter = _n_iters_per_thread * _thread_num
            + (_thread_num < _n_iters_extra ? _thread_num : _n_iters_extra);
          const $BaseTypeExpr{varType} _num_iters = _n_iters_per_thread 
            + (_thread_num < _n_iters_extra ? 1 : 0);

          for ($BaseTypeExpr{varType} $Name{var} = _first_iter; 
                $Name{var} < _first_iter + _num_iters; $Name{var}++) {
            $Stmt{loopBody}
          }

          0;
        })
      },
      loc, spawnAnnts);

  forwards to 
    if !annts.numParallelThreads.isJust
    then warnStmt([err(loc, "Parallel for-loop is missing a thread number specifier")])
    else ableC_Stmt {
      {
        const int _n_threads = $Expr{annts.numParallelThreads.fromJust};
        if (__builtin_expect(_n_threads < 1, 0)) {
          fprintf(stderr, 
            $stringLiteralExpr{s"Parallel for-loop must have positive number of threads ({loc.unparse})"});
          exit(-1);
        }

        const $BaseTypeExpr{varType} _n_iters = $Expr{bound};
        const $BaseTypeExpr{varType} _n_iters_per_thread = _n_iters / _n_threads;
        const $BaseTypeExpr{varType} _n_iters_extra = _n_iters % _n_threads;

        for (int _thread_num = 0; _thread_num < _n_threads; _thread_num++) {
          $Stmt{spawnStmt}
        }
      }
    };
}

function parallelToSpawnAnnts
SpawnAnnotations ::= annts::ParallelAnnotations
{
  return 
    case annts of
    | consParallelAnnotations(hd, tl) ->
      case hd of
      | parallelByAnnotation(e) -> 
          consSpawnAnnotations(
            spawnByAnnotation(e, location=hd.location), 
            parallelToSpawnAnnts(tl))
      | parallelInAnnotation(g) ->
          consSpawnAnnotations(
            spawnInAnnotation(g, location=hd.location), 
            parallelToSpawnAnnts(tl))
      | parallelPublicAnnotation(n) ->
          consSpawnAnnotations(
            spawnPublicAnnotation(n, location=hd.location), 
            parallelToSpawnAnnts(tl))
      | parallelPrivateAnnotation(n) ->
          consSpawnAnnotations(
            spawnPrivateAnnotation(n, location=hd.location), 
            parallelToSpawnAnnts(tl))
      | parallelGlobalAnnotation(n) ->
          consSpawnAnnotations(
            spawnGlobalAnnotation(n, location=hd.location), 
            parallelToSpawnAnnts(tl))
      | _ -> parallelToSpawnAnnts(tl)
      end
    | nilParallelAnnotations() -> nilSpawnAnnotations()
    end;
}

abstract production thrdpoolParallelNew
top::Expr ::= args::Exprs
{
  local localErrors :: [Message] =
    args.errors 
    ++
    case args of
    | consExpr(e, nilExpr()) when e.typerep.isIntegerType -> []
    | _ -> [err(top.location, "Thrdpool parallel system should be initialized with one integer argument")]
    end;

  top.pp = ppConcat([text("new thrdpool parallel"), 
    parens(ppImplode(text(", "), args.pps))]);

  local nmbrg::SystemNumbering = systemNumbering();
  nmbrg.lookupParName = "thrdpool";

  local numThreads :: Expr = case args of consExpr(e, nilExpr()) -> e
                              | _ -> error("Error in arguments reported via errors attribute") end;
  local sysIndex :: Integer = nmbrg.parNameIndex;

  forwards to 
    if !null(localErrors)
    then errorExpr(localErrors, location=top.location)
    else ableC_Expr {
      ({
        proto_typedef pthread_t;

        struct __ableC_system_info* ptr = malloc(sizeof(struct __ableC_system_info));

        ptr->system_id = $intLiteralExpr{sysIndex};
        ptr->block = __thrdpool_block_func;
        ptr->unblock = __thrdpool_unblock_func;
        
        struct __thrdpool_system_info* info = malloc(sizeof(struct __thrdpool_system_info));
        info->num_thrds = $Expr{numThreads};

        if (__builtin_expect(info->num_thrds < 1, 0)) {
          free(info);
          fprintf(stderr, 
            $stringLiteralExpr{s"Attempted to create a thread pool with non-positive number of threads (${top.location.unparse})\n"});
          exit(-1);
        }

        info->threads = malloc(sizeof(pthread_t) * info->num_thrds);
        if (__builtin_expect(info->threads == (void*) 0, 0)) {
          free(info);
          fprintf(stderr, 
            $stringLiteralExpr{s"Error allocating memory in thread pool creation (${top.location.unparse})\n"});
          exit(-1);
        }

        ptr->system_data = info;
        
        checked_pthread_mutex_init(&(info->lk), (void*) 0);
        checked_pthread_cond_init(&(info->cv), (void*) 0);
        info->work_head = (void*) 0;
        info->work_tail = (void*) 0;
        
        for (int thrd_num = 0; thrd_num < info->num_thrds; thrd_num++) {
          checked_pthread_create(info->threads + thrd_num, (void*) 0, __thrdpool_launcher, ptr);
        }

        ptr;
      })
    };
}

abstract production thrdpoolParallelDelete
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
          struct __ableC_system_info* _sys = 
            (struct __ableC_system_info*) $Expr{e};
          struct __thrdpool_system_info* _pool =
            (struct __thrdpool_system_info*) _sys->system_data;

          checked_pthread_mutex_lock(&(_pool->lk));

          if (__builtin_expect(_pool->work_head != (void*) 0, 0)) {
            fprintf(stderr, 
              $stringLiteralExpr{s"Attempted to delete a thread pool with remaining work (${e.location.unparse})\n"});
            exit(-1);
          }

          for (int thrd_num = 0; thrd_num < _pool->num_thrds; thrd_num++) {
            struct __thrdpool_work_item* work = malloc(sizeof(struct __thrdpool_work_item));
            work->started = -1;

            work->next = _pool->work_head;
            _pool->work_head = work;

            if (__builtin_expect(work->next == (void*) 0, 0)) {
              _pool->work_tail = work;
            }
          }

          checked_pthread_cond_broadcast(&(_pool->cv));
          checked_pthread_mutex_unlock(&(_pool->lk));

          for (int thrd_num = 0; thrd_num < _pool->num_thrds; thrd_num++) {
            int errnum = pthread_join(_pool->threads[thrd_num], (void*) 0);
            if (__builtin_expect(errnum, 0)) {
              fprintf(stderr, $stringLiteralExpr{s"Error in pthread_join (${e.location.unparse}): %s\n"}, strerror(errnum));
            }
          }

          checked_pthread_mutex_destroy(&(_pool->lk));
          checked_pthread_cond_destroy(&(_pool->cv));
          free(_pool->threads);

          free(_pool);
          free(_sys);
        }
      };
}
