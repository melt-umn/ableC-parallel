grammar edu:umn:cs:melt:exts:ableC:parallel:exts:synchronization:abstractsyntax;

type Actions = [Pair<ActionType [SignalAction]>];

type Accesses = [Pair<AccessType SynchronizedValue>];

synthesized attribute actions :: Either<Actions Accesses>;

nonterminal SynchronizedValue with actions;

-- Used when we allow direct modification of this value
abstract production synchronizedActions
top::SynchronizedValue ::= acts::Actions
{
  top.actions = left(acts);
}

-- Used when we allow modification of something within this value
abstract production synchronizedAccesses
top::SynchronizedValue ::= accs::Accesses
{
  top.actions = right(accs);
}

-- condition name (raw), is not condition, expr for loop
synthesized attribute conditions :: [Pair<String Pair<Boolean Expr>>];
synthesized attribute syncValue :: SynchronizedValue;

nonterminal SynchronizationDesc with conditions, syncValue;
abstract production synchronizationDesc
top::SynchronizationDesc ::= conds::[Pair<String Pair<Boolean Expr>>] 
                            val::SynchronizedValue
{
  top.conditions = conds;
  top.syncValue = val;
}

nonterminal ActionType;
abstract production increaseAction
top::ActionType ::= amt::Maybe<Integer> { }
abstract production decreaseAction
top::ActionType ::= amt::Maybe<Integer> { }
abstract production setEqAction
top::ActionType ::= amt::Integer { }
abstract production setNeqAction
top::ActionType ::= amt::Integer { }

nonterminal AccessType;
abstract production memberAccess
top::AccessType ::= nm::String arrow::Boolean { }
abstract production arrayAccess
top::AccessType ::= { }
abstract production derefAccess
top::AccessType ::= { }

function produceSynchronizationDesc
Either<SynchronizationDesc [Message]> ::= conds::OptionalConds 
                                          env::Decorated Env
                                          loc::Location
{
  local conditionExprs :: [Pair<String Expr>] =
    case conds of
    | noConds() -> []
    | withConds(cnds, _) -> extractConditions(cnds)
    end;

  local signals :: [Signal] =
    case conds of
    | noConds() -> []
    | withConds(_, s) -> extractSignals(s)
    end;

  local condList :: [Pair<String Pair<Boolean Expr>>] =
    map(\p::Pair<String Boolean> ->
      pair(p.fst, 
        pair(p.snd, 
          head(
            filter(
              \c::Pair<String Expr> -> c.fst == p.fst,
              conditionExprs
            )
          ).snd
        )
      ),
      conds.condVars
    );

  local signalVals :: [Either<SynchronizedValue [Message]>] 
    = map(\s::Signal -> 
        toSynchronizedValue(decorate s with {env=env;}), 
        signals);
  local sigPart :: Pair<[SynchronizedValue] [[Message]]> =
    partitionEithers(signalVals);
  local localErrors :: [Message] = concat(sigPart.snd);

  -- Combine things together into the appropriate tree structure
  local collapsed :: Either<SynchronizedValue [Message]> = 
    collapseValues(sigPart.fst, loc);

  return
    if !null(localErrors)
    then right(localErrors)
    else case conds of
         | noConds() -> left(synchronizationDesc([], synchronizedAccesses([])))
         | withConds(cnds, _) ->
           if collapsed.isRight
            then right(collapsed.fromRight)
            else left(
              synchronizationDesc(
                condList,
                collapsed.fromLeft
              )
            )
         end;
}

function extractConditions
[Pair<String Expr>] ::= conds::Conditions
{
  return 
    case conds of
    | nilCondition() -> []
    | consCondition(condition(nm, ex), tl) ->
        pair(nm.name, ex) :: extractConditions(tl)
    end;
}

function extractSignals
[Signal] ::= signals::Signals
{
  return
    case signals of
    | nilSignal() -> []
    | consSignal(s, tl) -> s :: extractSignals(tl)
    end;
}

function toSynchronizedValue
Either<SynchronizedValue [Message]> ::= sig::Decorated Signal
{
  local ex :: Decorated Expr = case sig of signal(ex, _, _) -> ex end;
  local mod :: ModAction = case sig of signal(_, mod, _) -> mod end;
  local signalAction :: SignalAction = 
    case sig of signal(_, _, act) -> act end;

  local actionType :: ActionType =
    case mod of
    | modIncrease(amt) -> increaseAction(amt)
    | modDecrease(amt) -> decreaseAction(amt)
    | modEquals(amt) -> setEqAction(amt)
    | modNotEquals(amt) -> setNeqAction(amt)
    end;

  local thisAction :: SynchronizedValue = 
    synchronizedActions(pair(actionType, signalAction :: []) :: []);

  return exprToSynchronizedValue(ex, thisAction);
}

function exprToSynchronizedValue
Either<SynchronizedValue [Message]> ::= e::Decorated Expr inner::SynchronizedValue
{
  return
    case e of
    | declRefExpr(name("this")) -> left(inner)
    | parenExpr(i) -> exprToSynchronizedValue(i, inner)
    | ovrld:arraySubscriptExpr(i, declRefExpr(name("_"))) ->
        exprToSynchronizedValue(i,
          synchronizedAccesses(pair(arrayAccess(), inner) :: []))
    | ovrld:dereferenceExpr(i) ->
        exprToSynchronizedValue(i, 
          synchronizedAccesses(pair(derefAccess(), inner) :: []))
    | ovrld:memberExpr(i, arrow, name(nm)) ->
        exprToSynchronizedValue(i,
          synchronizedAccesses(pair(memberAccess(nm, arrow), inner) :: []))
    | _ -> right(err(e.location, "Expression is not supported for the signal value") :: [])
    end;
}

function collapseValues
Either<SynchronizedValue [Message]> ::= vals::[SynchronizedValue] loc::Location
{
  -- Actions, Accesses
  local partitioned :: Pair<[SynchronizedValue] [SynchronizedValue]> =
    partition(\v :: SynchronizedValue -> 
                case v of
                | synchronizedActions(_) -> true
                | synchronizedAccesses(_) -> false
                end,
              vals);
  
  local localErrors :: [Message] =
    case partitioned of
    | pair([], []) -> error("Internal Error") -- Should not happen
    | pair(actions, []) -> []
    | pair([], accesses) -> [] -- Errors about proper usage should be caught
                               -- elsewhere by typechecking
    | _ -> [err(loc, "The set of signal values has unresolvable conflicts")]
          -- TODO: This is a horrible error message
    end;

  local collapsedActions :: Actions =
    concatPair(foldr(\act::Pair<ActionType [SignalAction]> lst::Pair<Actions Actions> ->
      case act.fst of
      | increaseAction(just(_)) -> pair(insertAction(act, lst.fst), lst.snd)
      | increaseAction(nothing()) -> pair(lst.fst, insertAction(act, lst.snd))
      | decreaseAction(just(_)) -> pair(insertAction(act, lst.fst), lst.snd)
      | decreaseAction(nothing()) -> pair(lst.fst, insertAction(act, lst.snd))
      | setEqAction(_) -> pair(insertAction(act, lst.fst), lst.snd)
      | setNeqAction(_) -> pair(insertAction(act, lst.fst), lst.snd)
      end,
      pair([], []), -- 1st for specific values, 2nd for catch-alls for +=/-=
      flatMap((\s::SynchronizedValue -> s.actions.fromLeft), vals)
    ));

  local collapsedAccesses :: Either<Accesses [Message]> =
    collapseAccesses(flatMap(\s::SynchronizedValue -> s.actions.fromRight, vals),
      loc);

  return
    if !null(localErrors)
    then right(localErrors)
    else 
      case partitioned of
      | pair(actions, []) -> left(synchronizedActions(collapsedActions))
      | pair([], accesses) ->
          if collapsedAccesses.isLeft
          then left(synchronizedAccesses(collapsedAccesses.fromLeft))
          else right(collapsedAccesses.fromRight)
      | _ -> error("This case reported as an error in localErrors")
      end;
}

function concatPair
[a] ::= p::Pair<[a] [a]>
{
  return p.fst ++ p.snd;
}

function insertAction
Actions ::= act::Pair<ActionType [SignalAction]> lst::Actions
{
  return
    case lst of
    | [] -> act :: []
    | pair(aT, sAcs) :: tl ->
        case aT, act.fst of
        | increaseAction(just(v1)), increaseAction(just(v2)) when v1 == v2 ->
            pair(aT, act.snd ++ sAcs) :: tl
        | increaseAction(nothing()), increaseAction(nothing()) -> 
            pair(aT, act.snd ++ sAcs) :: tl
        | decreaseAction(just(v1)), decreaseAction(just(v2)) when v1 == v2 ->
            pair(aT, act.snd ++ sAcs) :: tl
        | decreaseAction(nothing()), decreaseAction(nothing()) ->
            pair(aT, act.snd ++ sAcs) :: tl
        | setEqAction(v1), setEqAction(v2) when v1 == v2 ->
            pair(aT, act.snd ++ sAcs) :: tl
        | setNeqAction(v1), setNeqAction(v2) when v1 == v2 ->
            pair(aT, act.snd ++ sAcs) :: tl
        | _, _ -> pair(aT, sAcs) :: insertAction(act, tl)
        end
    end;
}

-- type Accesses = [Pair<AccessType SynchronizedValue>];
-- abstract production memberAccess (AccessType ::= String Boolean)
-- abstract production arrayAccess  (AccessType ::=               )
-- abstract production derefAccess  (AccessType ::=               )
function collapseAccesses
Either<Accesses [Message]> ::= accs::Accesses loc::Location
{
  local collected :: [Pair<AccessType [SynchronizedValue]>] =
    foldr(insertAccess, [], accs);

  local collapsed :: [Either<Pair<AccessType SynchronizedValue> [Message]>] =
    map(\p::Pair<AccessType [SynchronizedValue]> ->
      let collapse :: Either<SynchronizedValue [Message]> =
          collapseValues(p.snd, loc)
      in if collapse.isLeft
         then left(pair(p.fst, collapse.fromLeft))
         else right(collapse.fromRight)
      end,
      collected);
  local result :: Accesses =
    map(\e::Either<Pair<AccessType SynchronizedValue> [Message]> -> e.fromLeft,
      collapsed);

  local localErrors :: [Message] =
    flatMap(\e::Either<Pair<AccessType SynchronizedValue> [Message]> ->
      if e.isLeft then [] else e.fromRight,
      collapsed);

  return
    if !null(localErrors)
    then right(localErrors)
    else left(result);
}

function insertAccess
[Pair<AccessType [SynchronizedValue]>] ::= acc::Pair<AccessType SynchronizedValue>
                                        lst::[Pair<AccessType [SynchronizedValue]>]
{
  return
    case lst of
    | [] -> pair(acc.fst, acc.snd :: []) :: []
    | pair(aT, vals) :: tl ->
        case aT, acc.fst of
        | arrayAccess(), arrayAccess() -> 
            pair(aT, acc.snd :: vals) :: tl
        | derefAccess(), derefAccess() ->
            pair(aT, acc.snd :: vals) :: tl
        | memberAccess(n1, b1), memberAccess(n2, b2) when n1 == n2 && b1 == b2
          -> pair(aT, acc.snd :: vals) :: tl
        | _, _ -> pair(aT, vals) :: insertAccess(acc, tl)
        end
    end;
}
