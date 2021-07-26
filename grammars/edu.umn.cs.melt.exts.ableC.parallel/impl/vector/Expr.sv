grammar edu:umn:cs:melt:exts:ableC:parallel:impl:vector;

synthesized attribute vectorizeErrors :: [Message] occurs on Expr;
synthesized attribute vectorizeIsArray :: Boolean occurs on Expr;
synthesized attribute vectorizeArrays :: ts:Set<String> occurs on Expr;

functor attribute vectorizeForm occurs on Expr;
propagate vectorizeForm on Expr excluding arraySubscriptExpr;

inherited attribute vectorizeVar :: String occurs on Expr;
propagate vectorizeVar on Expr;

flowtype vectorizeErrors {vectorizeVar, env, controlStmtContext} on Expr;

aspect production exprStmt
top::Stmt ::= d::Expr
{
  -- Propagate a bogus name that isn't a valid identifier
  d.vectorizeVar = "---error(not a valid variable name)";
}

aspect default production
top::Expr ::=
{
  top.vectorizeErrors = [err(top.location, "This expression is not supported in a vector parallel for-loop")];
  top.vectorizeIsArray = false;
  top.vectorizeArrays = ts:empty();
}

aspect production parenExpr
top::Expr ::= e::Expr
{
  top.vectorizeErrors = e.vectorizeErrors;
  top.vectorizeIsArray = e.vectorizeIsArray;
  top.vectorizeArrays = e.vectorizeArrays;
}
aspect production transformedExpr
top::Expr ::= original::Expr resolved::Expr
{
  top.vectorizeErrors = resolved.vectorizeErrors;
  top.vectorizeIsArray = resolved.vectorizeIsArray;
  top.vectorizeArrays = resolved.vectorizeArrays;
}
aspect production memberExpr
top::Expr ::= lhs::Expr deref::Boolean rhs::Name
{
  top.vectorizeErrors = lhs.vectorizeErrors;
  top.vectorizeArrays = lhs.vectorizeArrays;
}
aspect production eqExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors
    ++ if lhs.vectorizeIsArray then []
       else [err(lhs.location, "Left-hand side of assignment in a vector parallel for-loop must be an array access")];
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production addEqExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors
    ++ if lhs.vectorizeIsArray then []
       else [err(lhs.location, "Left-hand side of assignment in a vector parallel for-loop must be an array access")];
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production subEqExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors
    ++ if lhs.vectorizeIsArray then []
       else [err(lhs.location, "Left-hand side of assignment in a vector parallel for-loop must be an array access")];
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production mulEqExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors
    ++ if lhs.vectorizeIsArray then []
       else [err(lhs.location, "Left-hand side of assignment in a vector parallel for-loop must be an array access")];
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production divEqExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors
    ++ if lhs.vectorizeIsArray then []
       else [err(lhs.location, "Left-hand side of assignment in a vector parallel for-loop must be an array access")];
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production modEqExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors
    ++ if lhs.vectorizeIsArray then []
       else [err(lhs.location, "Left-hand side of assignment in a vector parallel for-loop must be an array access")];
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production andEqExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors
    ++ if lhs.vectorizeIsArray then []
       else [err(lhs.location, "Left-hand side of assignment in a vector parallel for-loop must be an array access")];
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production orEqExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors
    ++ if lhs.vectorizeIsArray then []
       else [err(lhs.location, "Left-hand side of assignment in a vector parallel for-loop must be an array access")];
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production xorEqExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors
    ++ if lhs.vectorizeIsArray then []
       else [err(lhs.location, "Left-hand side of assignment in a vector parallel for-loop must be an array access")];
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production addExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors;
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production subExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors;
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production mulExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors;
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production divExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors;
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production modExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors;
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production andBitExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors;
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production orBitExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors;
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production xorExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors;
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production equalsExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors;
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production notEqualsExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors;
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production gtExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors;
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production ltExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors;
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production gteExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors;
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production lteExpr
top::Expr ::= lhs::Expr rhs::Expr 
{
  top.vectorizeErrors = lhs.vectorizeErrors ++ rhs.vectorizeErrors;
  top.vectorizeArrays = ts:union(lhs.vectorizeArrays, rhs.vectorizeArrays);
}
aspect production realConstant
top::Expr ::= c::NumericConstant
{
  top.vectorizeErrors = [];
}
aspect production dereferenceExpr
top::Expr ::= e::Expr
{
  top.vectorizeErrors = e.vectorizeErrors;
  top.vectorizeArrays = e.vectorizeArrays;
}
aspect production positiveExpr
top::Expr ::= e::Expr
{
  top.vectorizeErrors = e.vectorizeErrors;
  top.vectorizeArrays = e.vectorizeArrays;
}
aspect production negativeExpr
top::Expr ::= e::Expr
{
  top.vectorizeErrors = e.vectorizeErrors;
  top.vectorizeArrays = e.vectorizeArrays;
}
aspect production bitNegateExpr
top::Expr ::= e::Expr
{
  top.vectorizeErrors = e.vectorizeErrors;
  top.vectorizeArrays = e.vectorizeArrays;
}

aspect production declRefExpr
top::Expr ::= id::Name
{
  top.vectorizeErrors =
    if id.name == top.vectorizeVar
    then [err(top.location, "Loop variable of a vector parallel for-loop can only be used as an array index")]
    else [];
}

aspect production arraySubscriptExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  top.vectorizeIsArray = true;
  top.vectorizeErrors = lhs.vectorizeErrors ++
    case rhs of
    | declRefExpr(n) ->
        if n.name == top.vectorizeVar
        then []
        else [err(rhs.location, "Array accesses in a vector parallel for-loop must be at the loop variable")]
    | _ -> [err(rhs.location, "Array accesses in a vector parallel for-loop must be at the loop variable")]
    end
    ++
    case lhs of
    | declRefExpr(_) -> []
    | _ -> [err(lhs.location, "The left-hand side of array accesses in a vector parallel for-loop must be just a variable")]
    end;
  top.vectorizeArrays =
    case lhs of
    | declRefExpr(nm) -> ts:fromList(nm.name :: [])
    | _ -> ts:empty()
    end;

  top.vectorizeForm =
    case lhs of
    | declRefExpr(nm) -> ableC_Expr { $name{s"__vec_${nm.name}"}[$name{top.vectorizeVar}] }
    | _ -> top
    end;
}
