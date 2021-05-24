grammar edu:umn:cs:melt:exts:ableC:parallel:exts:synchronization:abstractsyntax;

abstract production synchronizationTypeExpr
top::BaseTypeExpr ::= q::Qualifiers inner::TypeName conds::OptionalConds
                      loc::Location
{
  top.pp = ppConcat([ppImplode(space(), q.pps), space(), 
                    text("synchronization<"), inner.pp, text(">"), space(), 
                    conds.pp]);

  conds.env = -- Adds `this` (as type inner) to the environment
    addEnv(
      valueDef("this", builtinValueItem(inner.typerep)) :: [],
      openScopeEnv(top.env));

  local partitionQualifiers :: Pair<[Qualifier] [Qualifier]> =
    partition(\q::Qualifier -> q.lockSystem.isJust, q.qualifiers);

  local lockQuals :: [Qualifier] = partitionQualifiers.fst;
  local otherQuals :: [Qualifier] = partitionQualifiers.snd;

  local localErrors :: [Message] =
    conds.errors ++ inner.errors
    ++
    (if null(lockQuals) || !null(tail(lockQuals))
     then [err(loc, "An 'synchronization' object must have a single qualifier specifying the implementation")]
     else []);

  local lockSystem :: LockSystem = head(lockQuals).lockSystem.fromJust;
  lockSystem.env = top.env;

  local mangledName :: String =
    s"${lockSystem.parName}_synchronized_${inner.typerep.mangledName}_with_${conds.mangledName}";

  local syncDesc :: Either<SynchronizationDesc [Message]> =
    produceSynchronizationDesc(conds, top.env, loc);

  local freeVars :: [Name] = 
    nub(filter(\n::Name -> n.name != "this", conds.freeVariables));

  local envGlobal :: Decorated Env = globalEnv(top.env);
  local freeVarErrs :: [Message] =
    flatMap(\n::Name -> 
      if !null((decorate n with {env=envGlobal;}).valueLookupCheck)
      then [err(loc, s"Variable '${n.name}' in conditions is not global")]
      else [],
      freeVars);
  local globals :: [Pair<Name Type>] =
    map(\n::Name -> 
      pair(n, (decorate n with {env=envGlobal;}).valueItem.typerep),
      freeVars);

  forwards to 
    if !null(localErrors)
    then errorTypeExpr(localErrors)
    else if syncDesc.isRight
    then errorTypeExpr(syncDesc.fromRight)
    else if !null(freeVarErrs)
    then errorTypeExpr(freeVarErrs)
    else
      injectGlobalDeclsTypeExpr(
        foldDecl(
          synchronizedTypeDecl(lockSystem, inner, conds, globals, 
            mangledName, loc) 
          :: inner.decls
        ),
        extTypeExpr(foldQualifier(otherQuals), 
            synchronizedType(lockSystem, inner.typerep, syncDesc.fromLeft, 
              top.pp, mangledName)));
}

-- Name and use of a condvar as a boolean (true represents the variable itself,
-- false is for use of `not var`)
synthesized attribute condVars :: [Pair<String Boolean>]; 

nonterminal OptionalConds with location, pp, errors, mangledName, env, 
  condVars, freeVariables;

abstract production noConds
top::OptionalConds ::= 
{
  top.pp = text("");
  top.errors := [];
  top.mangledName = "nothing";
  top.condVars = [];
  top.freeVariables := [];
}

abstract production withConds
top::OptionalConds ::= conds::Conditions signals::Signals
{
  top.pp = ppConcat([text("= {"), ppImplode(line(), conds.pps), line(), 
                    ppImplode(line(), signals.pps), text("}")]);

  conds.env = top.env;

  -- Add the variable `_` of integer type to permit arbitrary array accesses
  signals.env = 
    addEnv(
      valueDef("_", builtinValueItem(builtinType(nilQualifier(), signedType(intType())))) ::
      [],
      top.env);

  top.errors := conds.errors ++ signals.errors ++
    checkCondvars(conds.condVars, signals.condVars, top.location);

  top.mangledName = s"conds_${conds.mangledName}_signals_${signals.mangledName}";
  top.condVars = nub(signals.condVars);

  top.freeVariables := conds.freeVariables;
}


nonterminal Conditions with pps, errors, mangledName, env, condVars, freeVariables;

abstract production nilCondition
top::Conditions ::=
{
  top.pps = [];
  top.errors := [];
  top.mangledName = "nilCondition";
  top.condVars = [];
  top.freeVariables := [];
}

abstract production consCondition
top::Conditions ::= h::Condition tl::Conditions
{
  top.pps = h.pp :: tl.pps;
  top.errors := h.errors ++ tl.errors;
  top.mangledName = s"${h.mangledName}_cons_${tl.mangledName}";

  -- We should never access the boolean part of the condition declarations
  top.condVars = pair(h.condVarName, error("internal error")) :: tl.condVars;

  top.freeVariables := h.freeVariables ++ tl.freeVariables;
}


synthesized attribute condVarName :: String;
nonterminal Condition with pp, errors, mangledName, env, condVarName, freeVariables;

abstract production condition
top::Condition ::= nm::Name cond::Expr
{
  top.pp = ppConcat([text("condition"), space(), nm.pp, parens(cond.pp), semi()]);

  cond.controlStmtContext = initialControlStmtContext;

  local mangled :: Maybe<String> = mangleCondExpr(cond);

  top.errors := 
    cond.errors
    ++
    if mangled.isJust then []
    else [err(cond.location, "The expression given in the condition is not supported")];

  top.mangledName = s"cond_${nm.name}_${mangled.fromJust}";

  top.condVarName = nm.name;
  top.freeVariables := cond.freeVariables;
}


nonterminal Signals with pps, errors, mangledName, env, condVars;

abstract production nilSignal
top::Signals ::=
{
  top.pps = [];
  top.errors := [];
  top.mangledName = "nilSignal";
  top.condVars = [];
}

abstract production consSignal
top::Signals ::= h::Signal tl::Signals
{
  top.pps = h.pp :: tl.pps;
  top.errors := h.errors ++ tl.errors;
  top.mangledName = s"${h.mangledName}_cons_${tl.mangledName}";
  top.condVars = h.condVars ++ tl.condVars;
}


nonterminal Signal with pp, errors, location, mangledName, env, condVars;

abstract production signal
top::Signal ::= ex::Expr mod::ModAction sig::SignalAction
{
  top.pp = ppConcat([text("when"), parens(ex.pp), space(), mod.pp, space(),
                      text("then"), space(), sig.pp, semi()]);
 
  local mangled :: Maybe<String> = mangleAccessExpr(ex);

  ex.controlStmtContext = initialControlStmtContext;

  top.errors :=
    ex.errors 
    ++
    (if ex.typerep.isArithmeticType
    then []
    else
      case ex.typerep of
      | pointerType(_, _) -> []
      | _ -> [err(ex.location, "Signal expressions should be of arithmetic or pointer type")]
      end)
    ++
    (if mangled.isJust then []
    else [err(ex.location, "The expression given in the signal is not supported")]);

  top.mangledName = 
    s"${sig.mangledName}_${mangled.fromJust}_${mod.mangledName}";

  top.condVars = sig.condVars;
}

nonterminal ModAction with pp, mangledName;

abstract production modIncrease
top::ModAction ::= amt::Maybe<Integer>
{
  top.pp = ppConcat([text("+="), space(),
            if amt.isJust then text(toString(amt.fromJust)) else text("_")]);
  top.mangledName = 
    s"plus_eq_${if amt.isJust then toString(amt.fromJust) else "any"}";
}

abstract production modDecrease
top::ModAction ::= amt::Maybe<Integer>
{
  top.pp = ppConcat([text("-="), space(),
            if amt.isJust then text(toString(amt.fromJust)) else text("_")]);
  top.mangledName = 
    s"sub_eq_${if amt.isJust then toString(amt.fromJust) else "any"}";
}

abstract production modEquals
top::ModAction ::= amt::Integer
{
  top.pp = ppConcat([text("=="), space(), text(toString(amt))]);
  top.mangledName = s"set_eq_${toString(amt)}";
}

abstract production modNotEquals
top::ModAction ::= amt::Integer
{
  top.pp = ppConcat([text("!="), space(), text(toString(amt))]);
  top.mangledName = s"set_neq_${toString(amt)}";
}

nonterminal SignalAction with pp, mangledName, condVars;

{- We have an ignore so that you can add operations to the permissible set of
   operations on the value/a particular field, without actually having it
   cause a signal -}
abstract production signalIgnore
top::SignalAction ::= 
{ 
  top.pp = text("ignore"); 
  top.mangledName = "ignore";
  top.condVars = [];
}

abstract production signalSignal
top::SignalAction ::= isNot::Boolean nm::Name
{
  top.pp = ppConcat([text("signal"), space(), 
            if isNot then text("not ") else text(""), nm.pp]);
  top.mangledName = s"signal_${if isNot then "not_" else ""}${nm.name}";
  top.condVars = pair(nm.name, !isNot) :: [];
}

abstract production signalBroadcast
top::SignalAction ::= isNot::Boolean nm::Name
{
  top.pp = ppConcat([text("broadcast"), space(), 
            if isNot then text("not ") else text(""), nm.pp]);
  top.mangledName = s"broadcast_${if isNot then "not_" else ""}_${nm.name}";
  top.condVars = pair(nm.name, !isNot) :: [];
}

function mangleAccessExpr
Maybe<String> ::= e::Decorated Expr
{
  return
    case e of
    | declRefExpr(nm) -> just(nm.name)
    | parenExpr(e) -> let inner :: Maybe<String> = mangleAccessExpr(e)
                    in if inner.isJust then just("parens_" ++ inner.fromJust)
                                      else nothing() end
    | ableC_Expr { *$Expr{i}} -> let inner :: Maybe<String> = mangleAccessExpr(i)
                    in if inner.isJust then just("deref_" ++ inner.fromJust)
                                      else nothing() end
    | ableC_Expr { $Expr{i}.$Name{n}} -> 
        let inner :: Maybe<String> = mangleAccessExpr(i)
        in if inner.isJust then just(inner.fromJust ++ "_dot_" ++ n.name)
          else nothing() end
    | ableC_Expr { $Expr{i}->$Name{n}} ->
        let inner :: Maybe<String> = mangleAccessExpr(i)
        in if inner.isJust then just(inner.fromJust ++ "_arrow_" ++ n.name)
          else nothing() end
    | ableC_Expr { $Expr{i}[$Name{n}] } ->
        let inner :: Maybe<String> = mangleAccessExpr(i)
        in if inner.isJust then just(inner.fromJust ++ s"_${n.name}_elem")
          else nothing() end
    | _ -> nothing()
  end;
}

function mangleRhsExpr
Maybe<String> ::= e::Decorated Expr
{
  -- The things I can imagine wanting on the RHS (that we wouldn't want
  -- on the LHS) are a literal (integer, long, float, or double), a NULL 
  -- (which becomes (void*) 0  in the preprocessor), or a global variable
  -- TODO: Ideally we would probably support accessing values in a global,
  -- example: someGlobal.someName
  return 
    case e of
    | ableC_Expr {(void*) 0} -> just("null")
    | realConstant(c) -> just(c.mangledName)
    | _ -> mangleAccessExpr(e)
    end;
}

function mangleCondExpr
Maybe<String> ::= e::Decorated Expr
{
  return
    case e of
    | ableC_Expr { $Expr{lhs} <  $Expr{rhs} } ->
        let lres :: Maybe<String> = mangleAccessExpr(lhs) in
        let rres :: Maybe<String> = mangleRhsExpr(rhs) in
        if lres.isJust && rres.isJust
        then just(s"${lres.fromJust}_less_${rres.fromJust}")
        else nothing()
        end end
    | ableC_Expr { $Expr{lhs} <= $Expr{rhs} } ->
        let lres :: Maybe<String> = mangleAccessExpr(lhs) in
        let rres :: Maybe<String> = mangleRhsExpr(rhs) in
        if lres.isJust && rres.isJust
        then just(s"${lres.fromJust}_leq_${rres.fromJust}")
        else nothing()
        end end
    | ableC_Expr { $Expr{lhs} >  $Expr{rhs} } ->
        let lres :: Maybe<String> = mangleAccessExpr(lhs) in
        let rres :: Maybe<String> = mangleRhsExpr(rhs) in
        if lres.isJust && rres.isJust
        then just(s"${lres.fromJust}_greater_${rres.fromJust}")
        else nothing()
        end end
    | ableC_Expr { $Expr{lhs} >= $Expr{rhs} } ->
        let lres :: Maybe<String> = mangleAccessExpr(lhs) in
        let rres :: Maybe<String> = mangleRhsExpr(rhs) in
        if lres.isJust && rres.isJust
        then just(s"${lres.fromJust}_geq_${rres.fromJust}")
        else nothing()
        end end
    | ableC_Expr { $Expr{lhs} == $Expr{rhs} } ->
        let lres :: Maybe<String> = mangleAccessExpr(lhs) in
        let rres :: Maybe<String> = mangleRhsExpr(rhs) in
        if lres.isJust && rres.isJust
        then just(s"${lres.fromJust}_equal_${rres.fromJust}")
        else nothing()
        end end
    | ableC_Expr { $Expr{lhs} != $Expr{rhs} } ->
        let lres :: Maybe<String> = mangleAccessExpr(lhs) in
        let rres :: Maybe<String> = mangleRhsExpr(rhs) in
        if lres.isJust && rres.isJust
        then just(s"${lres.fromJust}_neq_${rres.fromJust}")
        else nothing()
        end end
    | _ -> 
      -- This checks that e has a type that is interpreted as true/false
      if e.typerep.defaultFunctionArrayLvalueConversion.isScalarType
      then mangleAccessExpr(e) -- An expression on its own is possibly valid, so try that
      else nothing()
    end;
}

function checkCondvars
[Message] ::= decls::[Pair<String Boolean>] generate::[Pair<String Boolean>]
              loc::Location
{
  return checkCondvarDuplicates(decls, loc)
          ++ checkCondvarSignals(decls, generate, loc);
}

function checkCondvarDuplicates
[Message] ::= decls::[Pair<String Boolean>] loc::Location
{
  return
    case decls of
    | [] -> []
    | pair(nm, _) :: tl ->
        if !null(filter(\p::Pair<String Boolean> -> p.fst == nm, tl))
        then err(loc, s"Multiple declarations of condition '${nm}'") 
              :: checkCondvarDuplicates(tl, loc)
        else checkCondvarDuplicates(tl, loc)
    end;
}

-- Compares the list of declared condvars and those which are even signaled.
-- If a particular condvar is never signaled then this produces an error.
function checkCondvarSignals
[Message] ::= decls::[Pair<String Boolean>] generate::[Pair<String Boolean>] 
              loc::Location
{
  return
    case decls of
    | [] -> []
    | pair(nm, _) :: tl -> 
        if null(filter(\p::Pair<String Boolean> -> p.fst == nm, generate))
        then err(loc, s"Condition '${nm}' is declared, but no signals are generated for it.") 
              :: checkCondvarSignals(tl, generate, loc)
        else checkCondvarSignals(tl, generate, loc)
    end;
}
