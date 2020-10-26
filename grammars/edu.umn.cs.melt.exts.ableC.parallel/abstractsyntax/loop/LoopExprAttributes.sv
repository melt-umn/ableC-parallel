grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:loop;

synthesized attribute parLoopBoundErrs :: [Message] occurs on Expr;
synthesized attribute parLoopUpdateErrs :: [Message] occurs on Expr;

-- The name of the loop variable, used to analyze bound and update
autocopy attribute parLoopVarName :: Name occurs on Expr, Decl, Stmt, MaybeExpr, 
  Exprs, ExprOrTypeName, Initializer, MaybeInitializer, Declarators, Declarator;

-- Bound for the loop variable
synthesized attribute parLoopBound :: Maybe<LoopBound> occurs on Expr;
-- The method by which the loop variable is updated
synthesized attribute parLoopUpdate :: Maybe<LoopUpdate> occurs on Expr;

aspect default production
top::Expr ::=
{
  top.parLoopBoundErrs = [err(top.location, "Invalid expression for parallel for-loop bound check")];
  top.parLoopUpdateErrs = [err(top.location, "Invalid expression for parallel for-loop update")];
  top.parLoopBound = nothing();
  top.parLoopUpdate = nothing();
}

function isVarExpr
Boolean ::= expr::Decorated Expr nm::Name
{
  return 
    case expr of
    | declRefExpr(id) -> id.name == nm.name
    | decExpr(e) -> isVarExpr(e, nm)
    | qualifiedExpr(_, e) -> isVarExpr(e, nm)
    | transformedExpr(_, e) -> isVarExpr(e, nm)
    | parenExpr(e) -> isVarExpr(e, nm)
    | explicitCastExpr(_, e) -> isVarExpr(e, nm)
    | _ -> false
    end;
}

function extractUpdate
Maybe<LoopUpdate> ::= expr::Decorated Expr nm::Name
{
  return
    case expr of
    | addExpr(lhs, rhs) when isVarExpr(lhs, nm) -> just(add(rhs))
    | addExpr(lhs, rhs) when isVarExpr(rhs, nm) -> just(add(lhs))
    | subExpr(lhs, rhs) when isVarExpr(lhs, nm) -> just(subtract(rhs))
    | decExpr(e) -> extractUpdate(e, nm)
    | qualifiedExpr(_, e) -> extractUpdate(e, nm)
    | transformedExpr(_, e) -> extractUpdate(e, nm)
    | parenExpr(e) -> extractUpdate(e, nm)
    | explicitCastExpr(_, e) -> extractUpdate(e, nm)
    | _ -> nothing()
    end;
}

function exprIndependent
Boolean ::= nm::Name expr::Decorated Expr
{
  return !containsBy(\n::Name m::Name -> n.name == m.name,
          nm, expr.freeVariables);
}

-- Loop update
aspect production eqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  local leftIsVar :: Boolean = isVarExpr(lhs, top.parLoopVarName);
  local equation :: Maybe<LoopUpdate> = extractUpdate(rhs, top.parLoopVarName);

  top.parLoopUpdateErrs = 
    if leftIsVar
    then  if equation.isJust
          then []
          else [err(top.location, "Parallel for-loop must update its loop variable by a constant value each iteration")]
    else [err(top.location, "Parallel for-loop must update its loop variable")];

  top.parLoopUpdate = 
    if leftIsVar
    then equation
    else nothing();
}

aspect production addEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  local leftIsVar :: Boolean = isVarExpr(lhs, top.parLoopVarName);
  local rightIndependent :: Boolean = exprIndependent(top.parLoopVarName, rhs);

  top.parLoopUpdateErrs =
    if leftIsVar
    then  if rightIndependent
          then []
          else [err(top.location, "Parallel for-loop must update its loop variable by a constant value each iteration")]
    else [err(top.location, "Parallel for-loop must update its loop variable")];

  top.parLoopUpdate =
    if leftIsVar
    then  if rightIndependent
          then just(add(rhs))
          else nothing()
    else nothing();
}

aspect production subEqExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  local leftIsVar :: Boolean = isVarExpr(lhs, top.parLoopVarName);
  local rightIndependent :: Boolean = exprIndependent(top.parLoopVarName, rhs);

  top.parLoopUpdateErrs =
    if leftIsVar
    then  if rightIndependent
          then []
          else [err(top.location, "Parallel for-loop must update its loop variable by a constant value")]
    else [err(top.location, "Parallel for-loop must update its loop variable")];

  top.parLoopUpdate =
    if leftIsVar
    then  if rightIndependent
          then just(subtract(rhs))
          else nothing()
    else nothing();
}

aspect production preIncExpr
top::Expr ::= e::Expr
{
  local isVar :: Boolean = isVarExpr(e, top.parLoopVarName);
  
  top.parLoopUpdateErrs = 
    if isVar
    then []
    else [err(top.location, "Parallel for-loop must update its loop variable")];

  top.parLoopUpdate = 
    if isVar
    then just(add(mkIntConst(1, builtin)))
    else nothing();
}

aspect production preDecExpr
top::Expr ::= e::Expr
{
  local isVar :: Boolean = isVarExpr(e, top.parLoopVarName);
  
  top.parLoopUpdateErrs = 
    if isVar
    then []
    else [err(top.location, "Parallel for-loop must update its loop variable")];

  top.parLoopUpdate = 
    if isVar
    then just(subtract(mkIntConst(1, builtin)))
    else nothing();
}

aspect production postIncExpr
top::Expr ::= e::Expr
{
  local isVar :: Boolean = isVarExpr(e, top.parLoopVarName);
  
  top.parLoopUpdateErrs = 
    if isVar
    then []
    else [err(top.location, "Parallel for-loop must update its loop variable")];

  top.parLoopUpdate = 
    if isVar
    then just(add(mkIntConst(1, builtin)))
    else nothing();
}

aspect production postDecExpr
top::Expr ::= e::Expr
{
  local isVar :: Boolean = isVarExpr(e, top.parLoopVarName);
  
  top.parLoopUpdateErrs = 
    if isVar
    then []
    else [err(top.location, "Parallel for-loop must update its loop variable")];

  top.parLoopUpdate = 
    if isVar
    then just(subtract(mkIntConst(1, builtin)))
    else nothing();
}

-- Loop condition
{- With all of these I will allow things of the form <v1> <op> <v2>
    where exactly ONE of <v1> and <v2> should contain the loop variable.
    That one can be a simple expression with respect to the loop variable.
    This can be one of:
      <var> +/- <const>
      <const> +/- <var>

    <var> +/- <const> <OP> <v2>
    =>  <var> <OP> <v2> -/+ <const>

    <const> + <var> <OP> <v2>
    =>  <var> <OP> <v2> - <const>

    <const> - <var> <OP> <v2>
    =>  <const> - <v2> <OP> <var>

    <v1> <OP> <var> +/- <const>
    =>  <v1> -/+ <const> <OP> <var>

    <v1> <OP> <const> + <var>
    =>  <v1> - <const> <OP> <var>

    <v1> <OP> <const> - <var>
    =>  <var> <OP> <const> - <v1>
-}
function extractVariableExpr
Maybe<Decorated Expr> ::= expr::Decorated Expr nm::Name
{
  return
    case expr of
    | declRefExpr(id) when id.name == nm.name -> just(expr)
    | addExpr(lhs, rhs) when isVarExpr(lhs, nm) || isVarExpr(rhs, nm) 
        -> just(expr)
    | subExpr(lhs, rhs) when isVarExpr(lhs, nm) || isVarExpr(rhs, nm)
        -> just(expr)
    | decExpr(e) -> extractVariableExpr(e, nm)
    | qualifiedExpr(_, e) -> extractVariableExpr(e, nm)
    | transformedExpr(_, e) -> extractVariableExpr(e, nm)
    | parenExpr(e) -> extractVariableExpr(e, nm)
    | explicitCastExpr(_, e) -> extractVariableExpr(e, nm)
    | _ -> nothing()
    end;
}

{- The idea of op and flipOp is that
          <var>  <OP> <expr> => op(expr)
    and   <expr> <OP> <var>  => flipOp(expr) -}
function transformBound
Pair<[Message] Maybe<LoopBound>> ::= lhs::Decorated Expr rhs::Decorated Expr
                                      nm::Name loc::Location
                                      op::(LoopBound ::= Expr) 
                                      flipOp::(LoopBound ::= Expr)
{
  local leftIndependent :: Boolean = exprIndependent(nm, lhs);
  local rightIndependent :: Boolean = exprIndependent(nm,rhs);

  local leftExpr :: Maybe<Decorated Expr> = extractVariableExpr(lhs, nm);
  local rightExpr :: Maybe<Decorated Expr> = extractVariableExpr(rhs, nm);

  local leftAdd :: Boolean =
    case leftExpr.fromJust of | addExpr(_, _) -> true | _ -> false end;
  local leftSub :: Boolean =
    case leftExpr.fromJust of | subExpr(_, _) -> true | _ -> false end;

  local rightAdd :: Boolean =
    case rightExpr.fromJust of | addExpr(_, _) -> true | _ -> false end;
  local rightSub :: Boolean =
    case rightExpr.fromJust of | subExpr(_, _) -> true | _ -> false end;

  local errs :: [Message] =
    if leftIndependent && rightIndependent
    then [err(loc, "The parallel for-loop condition must be dependent on the loop variable")]
    else if !leftIndependent && !rightIndependent
    then [err(loc, "The parallel for-loop condition can only have the loop variable on one side")]
    else if !leftIndependent && !leftExpr.isJust
    then [err(loc, "Only simple expressions involving the loop variable are allowed in parallel for-loop conditions")]
    else if !rightIndependent && !rightExpr.isJust
    then [err(loc, "Only simple expressions involving the loop variable are allowed in parallel for-loop conditions")]
    else [];

  local res :: Maybe<LoopBound> =
    if !leftIndependent && rightIndependent && leftExpr.isJust
    then -- f(<var>) <OP> <rhs>
      case leftExpr.fromJust of
      | addExpr(l, r) when isVarExpr(l, nm) -- <var> + <r> <OP> <rhs>
          -> just(op(subExpr(new(rhs), r, location=loc)))
      | addExpr(l, r) when isVarExpr(r, nm) -- <l> + <var> <OP> <rhs>
          -> just(op(subExpr(new(rhs), l, location=loc)))
      | subExpr(l, r) when isVarExpr(l, nm) -- <var> - <r> <OP> <rhs>
          -> just(op(addExpr(new(rhs), r, location=loc)))
      | subExpr(l, r) when isVarExpr(r, nm) -- <l> - <var> <OP> <rhs>
          -> just(flipOp(subExpr(l, new(rhs), location=loc)))
      | declRefExpr(id) when id.name == nm.name -- <var> <OP> <rhs>
          -> just(op(new(rhs)))
      | _ -> nothing()
      end
    else if !rightIndependent && leftIndependent && rightExpr.isJust
    then -- <lhs> <OP> f(<var>)
      case rightExpr.fromJust of
      | addExpr(l, r) when isVarExpr(l, nm) -- <lhs> <OP> <var> + <r>
          -> just(flipOp(subExpr(new(lhs), r, location=loc)))
      | addExpr(l, r) when isVarExpr(r, nm) -- <lhs> <OP> <l> + <var>
          -> just(flipOp(subExpr(new(lhs), l, location=loc)))
      | subExpr(l, r) when isVarExpr(l, nm) -- <lhs> <OP> <var> - <r>
          -> just(flipOp(addExpr(new(lhs), r, location=loc)))
      | subExpr(l, r) when isVarExpr(r, nm) -- <lhs> <OP> <l> - <var>
          -> just(op(subExpr(l, new(lhs), location=loc)))
      | declRefExpr(id) when id.name == nm.name -- <lhs> <OP> <var>
          -> just(flipOp(new(lhs)))
      | _ -> nothing()
      end
    else nothing();

  return pair(errs, res);
}

aspect production notEqualsExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  local analysis :: Pair<[Message] Maybe<LoopBound>> =
    transformBound(lhs, rhs, top.parLoopVarName, top.location,
      \expr::Expr -> notEqual(expr),
      \expr::Expr -> notEqual(expr));

  top.parLoopBoundErrs = analysis.fst;
  top.parLoopBound = analysis.snd;
}

aspect production gtExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  local analysis :: Pair<[Message] Maybe<LoopBound>> =
    transformBound(lhs, rhs, top.parLoopVarName, top.location,
      \expr::Expr -> greaterThan(expr),
      \expr::Expr -> lessThan(expr));

  top.parLoopBoundErrs = analysis.fst;
  top.parLoopBound = analysis.snd;
}

aspect production ltExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  local analysis :: Pair<[Message] Maybe<LoopBound>> =
    transformBound(lhs, rhs, top.parLoopVarName, top.location,
      \expr::Expr -> lessThan(expr),
      \expr::Expr -> greaterThan(expr));

  top.parLoopBoundErrs = analysis.fst;
  top.parLoopBound = analysis.snd;
}

aspect production gteExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  local analysis :: Pair<[Message] Maybe<LoopBound>> =
    transformBound(lhs, rhs, top.parLoopVarName, top.location,
      \expr::Expr -> greaterThanOrEqual(expr),
      \expr::Expr -> lessThanOrEqual(expr));

  top.parLoopBoundErrs = analysis.fst;
  top.parLoopBound = analysis.snd;
}

aspect production lteExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  local analysis :: Pair<[Message] Maybe<LoopBound>> =
    transformBound(lhs, rhs, top.parLoopVarName, top.location,
      \expr::Expr -> lessThanOrEqual(expr),
      \expr::Expr -> greaterThanOrEqual(expr));

  top.parLoopBoundErrs = analysis.fst;
  top.parLoopBound = analysis.snd;
}

-- Other propagating productions
{-aspect production decExpr
top::Expr ::= e::Decorated Expr
{
  top.parLoopBoundErrs = e.parLoopBoundErrs;
  top.parLoopUpdateErrs = e.parLoopUpdateErrs;
  top.parLoopBound = e.parLoopBound;
  top.parLoopUpdate = e.parLoopUpdate;
}-}

aspect production qualifiedExpr
top::Expr ::= q::Qualifiers e::Expr
{
  top.parLoopBoundErrs = e.parLoopBoundErrs;
  top.parLoopUpdateErrs = e.parLoopUpdateErrs;
  top.parLoopBound = e.parLoopBound;
  top.parLoopUpdate = e.parLoopUpdate;
}

aspect production transformedExpr
top::Expr ::= original::Expr resolved::Expr
{
  top.parLoopBoundErrs = resolved.parLoopBoundErrs;
  top.parLoopUpdateErrs = resolved.parLoopUpdateErrs;
  top.parLoopBound = resolved.parLoopBound;
  top.parLoopUpdate = resolved.parLoopUpdate;
}

aspect production parenExpr
top::Expr ::= e::Expr
{
  top.parLoopBoundErrs = e.parLoopBoundErrs;
  top.parLoopUpdateErrs = e.parLoopUpdateErrs;
  top.parLoopBound = e.parLoopBound;
  top.parLoopUpdate = e.parLoopUpdate;
}

aspect production explicitCastExpr
top::Expr ::= ty::TypeName e::Expr
{
  top.parLoopBoundErrs = e.parLoopBoundErrs;
  top.parLoopUpdateErrs = e.parLoopUpdateErrs;
  top.parLoopBound = e.parLoopBound;
  top.parLoopUpdate = e.parLoopUpdate;
}
