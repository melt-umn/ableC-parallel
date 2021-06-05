grammar edu:umn:cs:melt:exts:ableC:parallel:exts:mapReduce;

synthesized attribute arrayLength :: Expr;
synthesized attribute arrayResult :: Expr;
synthesized attribute shouldFree :: Boolean;
synthesized attribute elemType :: Type;
synthesized attribute fusionResult :: MapReduceArray;

-- Top-level map/reduce will actually evaluate the bound and store it into
-- a variable, others will just use that bound since maps do not change
-- the length of the array
inherited attribute emitBound :: Boolean;

nonterminal MapReduceArray with location, errors, env, controlStmtContext,
  arrayLength, arrayResult, shouldFree, elemType, emitBound, fusionResult, pp;

abstract production arrayExpr
top::MapReduceArray ::= arr::Name len::Expr
{
  top.pp = ppConcat([arr.pp, brackets(len.pp)]);
  top.errors := len.errors ++
    case arr.valueLookupCheck of
    | [] ->
      case arr.valueItem.typerep of
      | pointerType(_, _) -> []
      | arrayType(_, _, _, _) -> []
      | errorType() -> []
      | _ -> [err(arr.location, "Map-reduce only works with array or pointer types")]
      end
    | lst -> lst
    end;
  
  top.arrayLength = len;
  top.arrayResult = ableC_Expr { $Name{arr} };
  top.shouldFree = false;
  top.elemType = 
    case arr.valueItem.typerep of
    | pointerType(_, t) -> t
    | arrayType(t, _, _, _) -> t
    | _ -> error("Other types reported via errors attribute")
    end;

  top.fusionResult = top;
}

abstract production mapExpr
top::MapReduceArray ::= arr::MapReduceArray var::Name body::Expr annts::MapReduceAnnts
{
  top.pp = parens(ppConcat([text("map"), brackets(annts.pp), space(), arr.pp,
                          space(), text("by"), space(), text("\\"), var.pp,
                          space(), text("->"), space(), body.pp]));
  
  local cscx :: ControlStmtContext = initialControlStmtContext;
  arr.controlStmtContext = cscx;
  var.controlStmtContext = cscx;
  body.controlStmtContext = cscx;
  annts.controlStmtContext = cscx;

  local funcEnv :: Decorated Env =
    addEnv(
      valueDef(
        var.name,
        declaratorValueItem(
          decorate
            declarator(var, baseTypeExpr(), nilAttribute(), nothingInitializer())
          with {
            env=top.env; baseType=arr.elemType; typeModifierIn=baseTypeExpr();
            givenStorageClasses=nilStorageClass(); givenAttributes=nilAttribute();
            isTopLevel=false; isTypedef=false;
            controlStmtContext=cscx;
          }
        )
      ) :: [],
      top.env
    );
  body.env = funcEnv;

  local fusedArr :: MapReduceArray = arr.fusionResult;
  fusedArr.emitBound = false;
  fusedArr.controlStmtContext = cscx;
  fusedArr.env = top.env;

  top.errors := arr.errors ++ annts.errors ++ body.errors ++
    case annts.fusion of
    | just(reduceMapFusion()) -> [err(top.location, "A reduce-map fusion cannot be performed on a map")]
    | just(mapMapFusion()) ->
      case arr of
      | mapExpr(_, _, _, _) -> []
      | _ -> [err(top.location, "A map-map fusion cannot be performed because the inner value is not a map")]
      end
    | nothing() -> []
    end;

  top.arrayLength = arr.arrayLength;
  top.shouldFree = true;
  top.elemType = body.typerep;
 
  local replacedBody :: Expr =
    replaceExprVariable(body, var, ableC_Expr{__src[__idx]}, top.env,
                    cscx);

  -- TODO: Parallelism (if specified)
  top.arrayResult =
    ableC_Expr {
      ({
        $Stmt{if top.emitBound
              then ableC_Stmt {const unsigned long __mapReduceLength = $Expr{arr.arrayLength};} 
              else nullStmt()}
        $directTypeExpr{arr.elemType}* __src = $Expr{fusedArr.arrayResult};
        $directTypeExpr{top.elemType}* __res =
          malloc(sizeof($directTypeExpr{top.elemType}) * __mapReduceLength);

        for (unsigned long __idx = 0; __idx < __mapReduceLength; __idx++) {
          __res[__idx] = $Expr{replacedBody};
        }

        $Stmt{if arr.shouldFree
              then ableC_Stmt { free(__src); }
              else nullStmt()}
        __res;
      })
    };

  {- Replacing the variable with the appropriate transformation can make for
   - weird code since it may repeat those computations, but I think a
   - good optimizing compiler should be able to avoid most of that. The
   - advantage of this approach is that it makes code that is possible to
   - vectorize still, though I don't know how often that would come up -}
  top.fusionResult =
    case annts.fusion of
    | just(mapMapFusion()) ->
        case fusedArr of
        | mapExpr(inn, iV, iB, _) ->
            mapExpr(inn, iV,
              replaceExprVariable(body, var, iB, top.env, cscx),
              removeFusion(annts), location=top.location)
        | _ -> top
        end
    | _ -> top
    end;
}
