grammar edu:umn:cs:melt:exts:ableC:parallel:impl:vector;

abstract production vectorParallelSystem
top::ParallelSystem ::=
{
  top.parName = "vectorize";

  top.fSpawn = vectorSpawn;
  top.fFor = vectorFor;
  top.newProd = just(\a::Exprs l::Location -> vectorParallelNew(a, location=l));
  top.deleteProd = just(vectorParallelDelete);
}

aspect production systemNumbering
top::SystemNumbering ::=
{
  systems <- [vectorParallelSystem()];
}

abstract production vectorSpawn
top::Stmt ::= e::Expr loc::Location annts::SpawnAnnotations
{
  top.pp = ppConcat([text("spawn"), e.pp, semi()]);
  
  forwards to
    warnStmt([err(e.location,
      "Vector parallelism only allowed on parallel for-loops")]);
}

abstract production vectorFor
top::Stmt ::= loop::Stmt loc::Location annts::ParallelAnnotations
{
  top.pp = ppConcat([text("parallel"), top.pp]);
  top.functionDefs := loop.functionDefs;
  top.labelDefs := [];

  local localErrors :: [Message] =
    case loop of
    | ableC_Stmt { for($BaseTypeExpr{_} $Name{_} = host::(0); host::$Name{_} host::< $Expr{_}; host::$Name{_} host::++) { $Expr{_}; } } -> body.errors ++ body.vectorizeErrors ++ localTypeErrors
    | _ -> [err(loc, "Vectorized parallel for-loops must contain only a single assignment expression as their body")]
    end
    ++
    case annts.furtherBySystem of
    | nothing() ->
        case annts.publics, annts.privates, annts.globals, annts.inGroups, annts.numParallelThreads of
        | [], [], [], [], nothing() -> []
        -- Removing this error so that mapReduce can work with vectorize
        | _, _, _, _, _ -> [] --[err(loc, "Vector parallel for-loops do not support annotations (other than by) unless the par-by annotation is specified to parallelize the vectorized loop")]
        end
    | just(_) ->
        case systemType of
        | extType(_, parallelType(_)) -> [] --parBody.errors
        | _ -> [err(loc, "Argument to par-by annotation must be a parallel interface")]
        end
    end;

  -- type of variable, name of variable, loop bound, expression in the body
  local loopInfo :: (BaseTypeExpr, Name, Expr, Expr) =
    case loop of
    | ableC_Stmt { for($BaseTypeExpr{bt} $Name{i1} = host::(0); host::$Name{_} host::< $Expr{bound}; host::$Name{_} host::++) { $Expr{bd}; } }
      -> (bt, i1, bound, new(bd))
    | _ -> error("Bad for-loop repoted via errors attribute")
    end;

  local varType :: BaseTypeExpr = loopInfo.1;
  local var :: Name = loopInfo.2;
  local bound :: Expr = loopInfo.3;
  local body :: Expr = loopInfo.4;

  varType.env = top.env;
  varType.givenRefId = nothing();
  varType.controlStmtContext = top.controlStmtContext;

  body.env = addEnv(valueDef(var.name,
              declaratorValueItem(
                decorate
                  declarator(var, baseTypeExpr(), nilAttribute(),
                    nothingInitializer())
                with {env=top.env; baseType=varType.typerep;
                  typeModifierIn=baseTypeExpr(); givenAttributes=nilAttribute();
                  isTopLevel=false; isTypedef=false;
                  controlStmtContext=top.controlStmtContext;
                  givenStorageClasses = nilStorageClass();})) :: [],
            top.env);
  body.controlStmtContext = initialControlStmtContext;
  body.vectorizeVar = var.name;

  local arrays :: [String] = ts:toList(body.vectorizeArrays);
  local arrayTypes :: [Type] =
    map(\s::String ->
      (decorate ableC_Expr{$name{s}} with {env=top.env;
        controlStmtContext=initialControlStmtContext;}).typerep,
      arrays);
  local arrayElemType :: [Type] =
    map(\t::Type ->
      case t of
      | pointerType(_, t) -> t
      | arrayType(t, _, _, _) -> t
      | _ -> t
      end,
      arrayTypes);

  local headElemType :: Type = head(arrayElemType);
  local tailElemTypes :: [Type] = tail(arrayElemType);

  local headBT :: Maybe<BuiltinType> =
    case headElemType of
    | builtinType(nilQualifier(), realType(floatType())) -> just(realType(floatType()))
    | builtinType(nilQualifier(), realType(doubleType())) -> just(realType(doubleType()))
    | builtinType(nilQualifier(), signedType(charType())) -> just(signedType(charType()))
    | builtinType(nilQualifier(), signedType(shortType())) -> just(signedType(shortType()))
    | builtinType(nilQualifier(), signedType(intType())) -> just(signedType(intType()))
    | builtinType(nilQualifier(), signedType(longType())) -> just(signedType(longType()))
    | builtinType(nilQualifier(), signedType(longlongType())) -> just(signedType(longlongType()))
    | builtinType(nilQualifier(), unsignedType(charType())) -> just(unsignedType(charType()))
    | builtinType(nilQualifier(), unsignedType(shortType())) -> just(unsignedType(shortType()))
    | builtinType(nilQualifier(), unsignedType(intType())) -> just(unsignedType(intType()))
    | builtinType(nilQualifier(), unsignedType(longType())) -> just(unsignedType(longType()))
    | builtinType(nilQualifier(), unsignedType(longlongType())) -> just(unsignedType(longlongType()))
    | _ -> nothing()
    end;

  local localTypeErrors :: [Message] =
    case headBT of
    | just(_) -> []
    | _ -> [err(loc, "Arrays in vector parallel for-loop must be of an integer or floating-point type")]
    end
    ++
    flatMap(
      \t::Type ->
        checkTypesMatch(t, headBT, loc),
      tailElemTypes);

  local vectorType :: String =
    case headBT of
    | just(realType(floatType()))         -> "vecFloat"
    | just(realType(doubleType()))        -> "vecDouble"
    | just(signedType(charType()))        -> "vecSChar"
    | just(signedType(shortType()))       -> "vecSShort"
    | just(signedType(intType()))         -> "vecSInt"
    | just(signedType(longType()))        -> "vecSLong"
    | just(signedType(longlongType()))    -> "vecSLLong"
    | just(unsignedType(charType()))      -> "vecUChar"
    | just(unsignedType(shortType()))     -> "vecUShort"
    | just(unsignedType(intType()))       -> "vecUInt"
    | just(unsignedType(longType()))      -> "vecULong"
    | just(unsignedType(longlongType()))  -> "vecULLong"
    | _ -> error("Error condition reported via errors attributes")
    end;
  local vectorElemType :: TypeName =
    case headBT of
    | just(bt) -> typeName(builtinTypeExpr(nilQualifier(), bt), baseTypeExpr())
    | nothing() -> error("Error condition reported via errors attributes")
    end;
  local prepare :: Stmt =
    foldStmt(
      map(\s::String -> ableC_Stmt { 
          $tname{vectorType}* $name{s"__vec_${s}"} = ($tname{vectorType}*) $name{s};
        },
        arrays)
    );

  local vectorizedLoop :: Stmt =
    ableC_Stmt {
      for ($BaseTypeExpr{varType} $Name{var} = 0;
          $Name{var} < __bound / __vecNum;
          $Name{var}++) {
        $Expr{body.vectorizeForm};
      }
    };
  vectorizedLoop.env = loopEnv;

  local loopEnv :: Decorated Env =
    addEnv(
      valueDef("__bound",
        declaratorValueItem(
          decorate
            declarator(name("__bound", location=loc),
              baseTypeExpr(), nilAttribute(), nothingInitializer())
          with {env=top.env; baseType=varType.typerep;
            typeModifierIn=baseTypeExpr(); givenAttributes=nilAttribute();
            isTopLevel=false; isTypedef=false;
            controlStmtContext=top.controlStmtContext;
            givenStorageClasses=nilStorageClass();}
        )
      ) :: valueDef("__vecNum",
        declaratorValueItem(
          decorate
            declarator(name("__vecNum", location=loc),
              baseTypeExpr(), nilAttribute(), nothingInitializer())
          with {env=top.env;
            baseType=builtinType(nilQualifier(), unsignedType(longType()));
            typeModifierIn=baseTypeExpr(); givenAttributes=nilAttribute();
            isTopLevel=false; isTypedef=false;
            controlStmtContext=top.controlStmtContext;
            givenStorageClasses=nilStorageClass();}
        )
      ) :: map(\s::String ->
        valueDef(s"__vec_{s}",
          declaratorValueItem(
          decorate
            declarator(name(s"__vec_{s}", location=loc),
              baseTypeExpr(), nilAttribute(), nothingInitializer())
          with {env=top.env;
            baseType=
              (decorate ableC_BaseTypeExpr{$tname{vectorType}} with {
                env=top.env; givenRefId=nothing();
                controlStmtContext=top.controlStmtContext;
              }).typerep;
            typeModifierIn=pointerTypeExpr(nilQualifier(), baseTypeExpr());
            givenAttributes=nilAttribute(); isTopLevel=false; isTypedef=false;
            controlStmtContext=top.controlStmtContext;
            givenStorageClasses=nilStorageClass();}
          )
        ),
        arrays
      ),
      top.env
    );

  local bySystem :: Expr = annts.furtherBySystem.fromJust;
  bySystem.env = top.env;
  bySystem.controlStmtContext = top.controlStmtContext;

  local systemType :: Type = bySystem.typerep;

  local parAnnts :: ParallelAnnotations =
    consParallelAnnotations(
      parallelPrivateAnnotation(
        map(\s::String -> name(s"__vec_${s}", location=loc),
          arrays
        ),
        location=loc
      ),
      replaceFurtherWithBy(annts)
    );

  local parBody :: Stmt =
    case annts.furtherBySystem of
    | nothing() -> error("Parallel body not used except when par-by specified")
    | just(_) ->
      case systemType of
      | extType(_, parallelType(s)) -> s.fFor(vectorizedLoop, loc, parAnnts)
      | _ -> error("Bad type reported via errors attribute")
      end
    end;
  parBody.controlStmtContext = initialControlStmtContext;
  parBody.env = loopEnv;
                
  forwards to
    if !null(localErrors)
    then warnStmt(localErrors)
    else ableC_Stmt { 
      {
        proto_typedef size_t;
        $Stmt{prepare};
        
        $BaseTypeExpr{varType} __bound = $Expr{bound};
        const size_t __vecNum = 32 / sizeof($TypeName{vectorElemType});
        
        $Stmt{if annts.furtherBySystem.isJust then parBody else vectorizedLoop}
        
        for ($BaseTypeExpr{varType} $Name{var} = (__bound / __vecNum) * __vecNum;
            $Name{var} < __bound;
            $Name{var}++) {
          $Expr{body};
        }
      }
    };
}

abstract production vectorParallelNew
top::Expr ::= args::Exprs
{
  local localErrors :: [Message] =
    args.errors
    ++
    case args of
    | nilExpr() -> []
    | _ -> [err(top.location, "Vector parallelism should be initialized with no arguments")]
    end;

  top.pp = ppConcat([text("new"), space(), text("vector"), space(), text("parallel"),
              parens(ppImplode(comma(), args.pps))]);

  local nmbrg::SystemNumbering = systemNumbering();
  nmbrg.lookupParName = "vectorization";

  local sysIndex :: Integer = nmbrg.parNameIndex;

  forwards to
    if !null(localErrors)
    then errorExpr(localErrors, location=top.location)
    else ableC_Expr {
      ({
        struct __ableC_system_info* ptr = malloc(sizeof(struct __ableC_system_info));
        ptr->system_id = $intLiteralExpr{sysIndex};
        ptr->system_data = (void*) 0;
        ptr->block = (void*) 0;
        ptr->unblock = (void*) 0;
        ptr;
      })
    };
}

abstract production vectorParallelDelete
top::Stmt ::= e::Expr
{
  top.pp = ppConcat([text("delete"), e.pp]);
  top.functionDefs := [];
  top.labelDefs := [];

  forwards to
    if !null(e.errors)
    then warnStmt(e.errors)
    else ableC_Stmt {
        free((void*) $Expr{e});
      };
}

function checkTypesMatch
[Message] ::= ty::Type mbt::Maybe<BuiltinType> loc::Location
{
  return
    case mbt of
    | just(bt) ->
        case ty of
        | builtinType(nilQualifier(), b) ->
            case b, bt of
            | realType(floatType()), realType(floatType()) -> []
            | realType(doubleType()), realType(doubleType()) -> []
            | signedType(charType()), signedType(charType()) -> []
            | signedType(shortType()), signedType(shortType()) -> []
            | signedType(intType()), signedType(intType()) -> []
            | signedType(longType()), signedType(longType()) -> []
            | signedType(longlongType()), signedType(longlongType()) -> []
            | unsignedType(charType()), unsignedType(charType()) -> []
            | unsignedType(shortType()), unsignedType(shortType()) -> []
            | unsignedType(intType()), unsignedType(intType()) -> []
            | unsignedType(longType()), unsignedType(longType()) -> []
            | unsignedType(longlongType()), unsignedType(longlongType()) -> []
            | _, _ -> [err(loc, "All arrays in vector parallel for-loop must have the same element type")]
            end
        | _ -> [err(loc, "Arrays in vector parallel for-loop must be of an integer or floating-point type")]
        end
    | _ -> []
    end;
}

function replaceFurtherWithBy
ParallelAnnotations ::= annts::ParallelAnnotations
{
  return
    case annts of
    | nilParallelAnnotations() -> nilParallelAnnotations()
    | consParallelAnnotations(h, tl) ->
        case h of
        | parallelByAnnotation(_) -> replaceFurtherWithBy(tl)
        | parallelFurtherByAnnotation(e) ->
            consParallelAnnotations(
              parallelByAnnotation(e, location=h.location),
              replaceFurtherWithBy(tl)
            )
        | _ -> consParallelAnnotations(h, replaceFurtherWithBy(tl))
        end
    end;
}
