grammar edu:umn:cs:melt:exts:ableC:parallel:exts:synchronization:abstractsyntax;

{-
 - A held synchronized variable has one of four options:
 -  * Any action or access on it is allowed [unsyncd == true]
 -  * Certain actions are allowed [unsyncd == false, actions = left(...)]
 -  * All accesses are allowed, some main remain synchronized
 -        [unsyncd == false, actions = right(lst)]
 -  * The value must be used as an r-value so no accesses or actions
 -      are allowed
 -        [unsyncd == false, actions = left(lst), lst == [] ]
 -}

function accessValue
Expr ::= e::Expr mangledName::String
{
  return ableC_Expr { 
    ((struct $name{mangledName}*) $Expr{e})->value
  };
}

global asRealType :: (Expr ::= Expr Type) = exprAsType(_, _, location=builtinLoc("synchronized"));

abstract production heldType
top::ExtType ::= innerType::Type hostType::Type getObj::(Expr ::= Expr)
                unsyncd::Boolean actions::Either<Actions Accesses>
                sys::LockSystem nm::Name mangledName::String
                conds::[Pair<String Pair<Boolean Expr>>]
{
  -- FIXME
  top.canonicalType = error("Unexpected access of canonicalType on heldType");
  top.mangledName   = error("Unexpected access of mangledName on heldType");

  -- TODO: Not sure this is right
  top.isEqualTo     = \other::ExtType ->
    case other of
    | heldType(iT, _, _, _, _, _, _, _, _) -> compatibleTypes(innerType, iT, true, true)
    | _ -> false
    end;

  top.pp = ppConcat([text("held"), parens(
              ppConcat([innerType.lpp, space(), innerType.rpp]))]);
  top.host = hostType;
  
  top.baseTypeExpr = innerType.baseTypeExpr;
  top.typeModifierExpr = innerType.typeModifierExpr;
  top.integerPromotions = innerType.integerPromotions;
  top.defaultArgumentPromotions = innerType.integerPromotions;
  -- TODO: I don't understand defaultLvalueConversion, I worry it would be a problem
  top.defaultFunctionArrayLvalueConversion = innerType.defaultFunctionArrayLvalueConversion;
  top.isIntegerType = innerType.isIntegerType;
  top.isArithmeticType = innerType.isArithmeticType;
  top.isScalarType = innerType.isScalarType;
  top.isCompleteType = innerType.isCompleteType;
  top.maybeRefId := innerType.maybeRefId;

  local notAllowed :: (Expr ::= Location) = \loc::Location ->
    errorExpr([err(loc, "Address of operation is not allowed on a synchronized object")],
      location=loc);

  innerType.ovrld:otherType = top.ovrld:otherType;

  -- Never allow address of
  top.ovrld:addressOfProd = just(\e::Expr l::Location -> notAllowed(l));
  top.ovrld:addressOfArraySubscriptProd = just(\e::Expr i::Expr l::Location -> notAllowed(l));
  top.ovrld:addressOfCallProd = just(\e::Expr h::Exprs l::Location -> notAllowed(l));
  top.ovrld:addressOfMemberProd = just(\e::Expr b::Boolean n::Name l::Location -> notAllowed(l));

  -- These productions do not modify the value and produce an r-value, so they
  -- are always allowed and the result is a heldType that is allowed no accesses
  -- (since they are r-values this prevents them from ever being turned back into
  -- an l-value and therefore also prevents actions)
  top.ovrld:positiveProd = heldUnaryOperator(getObj, innerType.ovrld:positiveProd,
                              positiveExpr(_, location=_), sys, nm, mangledName, conds);
  top.ovrld:negativeProd = heldUnaryOperator(getObj, innerType.ovrld:negativeProd,
                              negativeExpr(_, location=_), sys, nm, mangledName, conds);
  top.ovrld:bitNegateProd = heldUnaryOperator(getObj, innerType.ovrld:bitNegateProd,
                              bitNegateExpr(_, location=_), sys, nm, mangledName, conds);
  top.ovrld:notProd = heldUnaryOperator(getObj, innerType.ovrld:notProd,
                        notExpr(_, location=_), sys, nm, mangledName, conds);

  top.ovrld:lAndProd = heldLBinaryOperator(getObj, innerType.ovrld:lAndProd,
                        andExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rAndProd = heldRBinaryOperator(getObj, innerType.ovrld:rAndProd,
                        andExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:lOrProd = heldLBinaryOperator(getObj, innerType.ovrld:lOrProd,
                        orExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rOrProd = heldRBinaryOperator(getObj, innerType.ovrld:rOrProd,
                        orExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:lAndBitProd = heldLBinaryOperator(getObj, innerType.ovrld:lAndBitProd,
                        andBitExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rAndBitProd = heldRBinaryOperator(getObj, innerType.ovrld:rAndBitProd,
                        andBitExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:lOrBitProd = heldLBinaryOperator(getObj, innerType.ovrld:lOrBitProd,
                        orBitExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rOrBitProd = heldRBinaryOperator(getObj, innerType.ovrld:rOrBitProd,
                        orBitExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:lXorProd = heldLBinaryOperator(getObj, innerType.ovrld:lXorProd,
                        xorExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rXorProd = heldRBinaryOperator(getObj, innerType.ovrld:rXorProd,
                        xorExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:lLshBitProd = heldLBinaryOperator(getObj, innerType.ovrld:lLshBitProd,
                        lshExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rLshBitProd = heldRBinaryOperator(getObj, innerType.ovrld:rLshBitProd,
                        lshExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:lRshBitProd = heldLBinaryOperator(getObj, innerType.ovrld:lRshBitProd,
                        rshExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rRshBitProd = heldRBinaryOperator(getObj, innerType.ovrld:rRshBitProd,
                        rshExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:lEqualsProd = heldLBinaryOperator(getObj, innerType.ovrld:lEqualsProd,
                        equalsExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rEqualsProd = heldRBinaryOperator(getObj, innerType.ovrld:rEqualsProd,
                        equalsExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:lNotEqualsProd = heldLBinaryOperator(getObj, innerType.ovrld:lNotEqualsProd,
                        notEqualsExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rNotEqualsProd = heldRBinaryOperator(getObj, innerType.ovrld:rNotEqualsProd,
                        notEqualsExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:lLtProd = heldLBinaryOperator(getObj, innerType.ovrld:lLtProd,
                        ltExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rLtProd = heldRBinaryOperator(getObj, innerType.ovrld:rLtProd,
                        ltExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:lGtProd = heldLBinaryOperator(getObj, innerType.ovrld:lGtProd,
                        gtExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rGtProd = heldRBinaryOperator(getObj, innerType.ovrld:rGtProd,
                        gtExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:lLteProd = heldLBinaryOperator(getObj, innerType.ovrld:lLteProd,
                        lteExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rLteProd = heldRBinaryOperator(getObj, innerType.ovrld:rLteProd,
                        lteExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:lGteProd = heldLBinaryOperator(getObj, innerType.ovrld:lGteProd,
                        gteExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rGteProd = heldRBinaryOperator(getObj, innerType.ovrld:rGteProd,
                        gteExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:lAddProd = heldLBinaryOperator(getObj, innerType.ovrld:lAddProd,
                        addExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rAddProd = heldRBinaryOperator(getObj, innerType.ovrld:rAddProd,
                        addExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:lSubProd = heldLBinaryOperator(getObj, innerType.ovrld:lSubProd,
                        subExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rSubProd = heldRBinaryOperator(getObj, innerType.ovrld:rSubProd,
                        subExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:lMulProd = heldLBinaryOperator(getObj, innerType.ovrld:lMulProd,
                        mulExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rMulProd = heldRBinaryOperator(getObj, innerType.ovrld:rMulProd,
                        mulExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:lDivProd = heldLBinaryOperator(getObj, innerType.ovrld:lDivProd,
                        divExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rDivProd = heldRBinaryOperator(getObj, innerType.ovrld:rDivProd,
                        divExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:lModProd = heldLBinaryOperator(getObj, innerType.ovrld:lModProd,
                        modExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rModProd = heldRBinaryOperator(getObj, innerType.ovrld:rModProd,
                        modExpr(_, _, location=_), sys, nm, mangledName, conds);

  top.ovrld:rEqProd = heldRBinaryOperator(getObj, innerType.ovrld:rEqProd,
                        eqExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rMulEqProd = heldRBinaryOperator(getObj, innerType.ovrld:rMulEqProd,
                        mulEqExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rDivEqProd = heldRBinaryOperator(getObj, innerType.ovrld:rDivEqProd,
                        divEqExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rModEqProd = heldRBinaryOperator(getObj, innerType.ovrld:rModEqProd,
                        modEqExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rAddEqProd = heldRBinaryOperator(getObj, innerType.ovrld:rAddEqProd,
                        addEqExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rSubEqProd = heldRBinaryOperator(getObj, innerType.ovrld:rSubEqProd,
                        subEqExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rLshEqProd = heldRBinaryOperator(getObj, innerType.ovrld:rLshEqProd,
                        lshEqExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rRshEqProd = heldRBinaryOperator(getObj, innerType.ovrld:rRshEqProd,
                        rshEqExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rAndEqProd = heldRBinaryOperator(getObj, innerType.ovrld:rAndEqProd,
                        andEqExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rXorEqProd = heldRBinaryOperator(getObj, innerType.ovrld:rXorEqProd,
                        xorEqExpr(_, _, location=_), sys, nm, mangledName, conds);
  top.ovrld:rOrEqProd = heldRBinaryOperator(getObj, innerType.ovrld:rOrEqProd,
                        orEqExpr(_, _, location=_), sys, nm, mangledName, conds);

  top.ovrld:callProd = heldCallOperator(getObj, innerType.ovrld:callProd,
                        callExpr(_, _, location=_), sys, nm, mangledName, conds);

  -- These operations directly modify the expression, and then produce some
  -- r-value, so we must check that the action is permitted and if it is we
  -- produce a type that is allowed no actions
  top.ovrld:preIncProd = heldUnaryAction(unsyncd, actions, getObj,
                            innerType.ovrld:preIncProd, preIncExpr(_, location=_),
                            increaseAction(just(1)), sys, nm, mangledName, conds);
  top.ovrld:preDecProd = heldUnaryAction(unsyncd, actions, getObj,
                            innerType.ovrld:preDecProd, preDecExpr(_, location=_),
                            decreaseAction(just(1)), sys, nm, mangledName, conds);
  top.ovrld:postIncProd = heldUnaryAction(unsyncd, actions, getObj,
                            innerType.ovrld:postIncProd, postIncExpr(_, location=_),
                            increaseAction(just(1)), sys, nm, mangledName, conds);
  top.ovrld:postDecProd = heldUnaryAction(unsyncd, actions, getObj,
                            innerType.ovrld:postDecProd, postDecExpr(_, location=_),
                            decreaseAction(just(1)), sys, nm, mangledName, conds);

  top.ovrld:eqMemberProd = heldMemberEqAction(innerType, hostType, getObj,
                              unsyncd, actions, sys, nm, mangledName, conds);

  top.ovrld:lEqProd = heldBinaryAction(unsyncd, actions, getObj,
                        innerType.ovrld:lEqProd, eqExpr(_, _, location=_),
                        (\e::Decorated Expr -> if e.integerConstantValue.isJust
                              then just(setEqAction(e.integerConstantValue.fromJust))
                              else nothing()),
                        sys, nm, mangledName, conds);
  top.ovrld:lAddEqProd = heldBinaryAction(unsyncd, actions, getObj,
                          innerType.ovrld:lAddEqProd, addEqExpr(_, _, location=_),
                          (\e::Decorated Expr -> just(increaseAction(e.integerConstantValue))),
                          sys, nm, mangledName, conds);
  top.ovrld:lSubEqProd = heldBinaryAction(unsyncd, actions, getObj,
                          innerType.ovrld:lSubEqProd, subEqExpr(_, _, location=_),
                          (\e::Decorated Expr -> just(decreaseAction(e.integerConstantValue))),
                          sys, nm, mangledName, conds);
  
  -- These are only allowed if any action is permitted (since we don't allow
  -- synchronization based on these operations) [unsyncd == true]
  -- we kinda cheat to get these to work by passing left([])
  top.ovrld:lMulEqProd = heldBinaryAction(unsyncd, left([]), getObj,
                          innerType.ovrld:lMulEqProd, mulEqExpr(_, _, location=_),
                          (\e::Decorated Expr -> just(error("Internal error"))),
                          sys, nm, mangledName, conds);
  top.ovrld:lDivEqProd = heldBinaryAction(unsyncd, left([]), getObj,
                          innerType.ovrld:lDivEqProd, divEqExpr(_, _, location=_),
                          (\e::Decorated Expr -> just(error("Internal error"))),
                          sys, nm, mangledName, conds);
  top.ovrld:lModEqProd = heldBinaryAction(unsyncd, left([]), getObj,
                          innerType.ovrld:lModEqProd, modEqExpr(_, _, location=_),
                          (\e::Decorated Expr -> just(error("Internal error"))),
                          sys, nm, mangledName, conds);
  top.ovrld:lLshEqProd = heldBinaryAction(unsyncd, left([]), getObj,
                          innerType.ovrld:lLshEqProd, lshEqExpr(_, _, location=_),
                          (\e::Decorated Expr -> just(error("Internal error"))),
                          sys, nm, mangledName, conds);
  top.ovrld:lRshEqProd = heldBinaryAction(unsyncd, left([]), getObj,
                          innerType.ovrld:lRshEqProd, rshEqExpr(_, _, location=_),
                          (\e::Decorated Expr -> just(error("Internal error"))),
                          sys, nm, mangledName, conds);
  top.ovrld:lAndEqProd = heldBinaryAction(unsyncd, left([]), getObj,
                          innerType.ovrld:lAndEqProd, andEqExpr(_, _, location=_),
                          (\e::Decorated Expr -> just(error("Internal error"))),
                          sys, nm, mangledName, conds);
  top.ovrld:lXorEqProd = heldBinaryAction(unsyncd, left([]), getObj,
                          innerType.ovrld:lXorEqProd, xorEqExpr(_, _, location=_),
                          (\e::Decorated Expr -> just(error("Internal error"))),
                          sys, nm, mangledName, conds);
  top.ovrld:lOrEqProd = heldBinaryAction(unsyncd, left([]), getObj,
                          innerType.ovrld:lOrEqProd, orEqExpr(_, _, location=_),
                          (\e::Decorated Expr -> just(error("Internal error"))),
                          sys, nm, mangledName, conds);

  -- And here we have to check whether the access is synchronized, and if so
  -- produce a type reflecting what is allowed on the result, otherwise we
  -- produce a type that allows any access or action
  top.ovrld:arraySubscriptProd = heldArrayAccess(unsyncd, actions, getObj,
                                    innerType.ovrld:arraySubscriptProd,
                                    sys, nm, mangledName, conds);
  top.ovrld:memberProd = heldMemberAccess(unsyncd, actions, getObj,
                              innerType, sys, nm, mangledName, conds);
  top.ovrld:dereferenceProd = heldDereferenceAccess(unsyncd, actions, getObj,
                                innerType.ovrld:dereferenceProd,
                                sys, nm, mangledName, conds);
}

function heldUnaryOperator
Maybe<ovrld:UnaryProd> ::= getObj::(Expr ::= Expr) innerProd::Maybe<ovrld:UnaryProd>
                                hostProd::ovrld:UnaryProd
                                sys::LockSystem nm::Name mangledName::String
                                conds::[Pair<String Pair<Boolean Expr>>]
{
  return
    just(\e::Expr loc::Location ->
      produceRvalExpr(
        case innerProd of
        | nothing() -> hostProd(getObj(e), loc)
        | just(prod) -> prod(getObj(e), loc)
        end,
        sys, nm, mangledName, conds,
        location=loc
      )
    );
}

function heldLBinaryOperator
Maybe<ovrld:BinaryProd> ::= getObj::(Expr ::= Expr) innerProd::Maybe<ovrld:BinaryProd>
                              hostProd::ovrld:BinaryProd
                              sys::LockSystem nm::Name mangledName::String
                              conds::[Pair<String Pair<Boolean Expr>>]
{
  return
    just(\lhs::Expr rhs::Expr loc::Location ->
      produceRvalExpr(
        case innerProd of
        | nothing() -> hostProd(getObj(lhs), heldCheckOtherSide(rhs, location=loc), loc)
        | just(prod) -> prod(getObj(lhs), heldCheckOtherSide(rhs, location=loc), loc)
        end,
        sys, nm, mangledName, conds,
        location=loc
      )
    );
}

function heldRBinaryOperator
Maybe<ovrld:BinaryProd> ::= getObj::(Expr ::= Expr) innerProd::Maybe<ovrld:BinaryProd>
                              hostProd::ovrld:BinaryProd
                              sys::LockSystem nm::Name mangledName::String
                              conds::[Pair<String Pair<Boolean Expr>>]
{
  return
    just(\lhs::Expr rhs::Expr loc::Location ->
      produceRvalExpr(
        case innerProd of
        | nothing() -> hostProd(heldCheckOtherSide(lhs, location=loc), getObj(rhs), loc)
        | just(prod) -> prod(heldCheckOtherSide(lhs, location=loc), getObj(rhs), loc)
        end,
        sys, nm, mangledName, conds,
        location=loc
      )
    );
}

function heldCallOperator
Maybe<(Expr ::= Expr Exprs Location)> ::= getObj::(Expr ::= Expr)
                              innerProd::Maybe<(Expr ::= Expr Exprs Location)>
                              hostProd::(Expr ::= Expr Exprs Location)
                              sys::LockSystem nm::Name mangledName::String
                              conds::[Pair<String Pair<Boolean Expr>>]
{
  return
    just(\e::Expr args::Exprs loc::Location ->
      produceRvalExpr(
        case innerProd of
        | nothing() -> hostProd(e, heldCheckExprs(args), loc)
        | just(prod) -> prod(e, heldCheckExprs(args), loc)
        end,
        sys, nm, mangledName, conds,
        location=loc
      )
    );
}

function heldUnaryAction
Maybe<ovrld:UnaryProd> ::= unsyncd::Boolean actions::Either<Actions Accesses>
                  getObj::(Expr ::= Expr)
                  innerProd::Maybe<ovrld:UnaryProd>
                  hostProd::ovrld:UnaryProd
                  desired::ActionType sys::LockSystem nm::Name
                  mangledName::String conds::[Pair<String Pair<Boolean Expr>>]
{
  return
    if unsyncd
    then heldUnaryOperator(getObj, innerProd, hostProd, sys, nm, mangledName, conds)
    else if actions.isRight
    then just(\e::Expr loc::Location ->
            errorExpr([err(loc, "Actions are not permitted on this object")],
              location=loc))
    else 
      let sigs::Maybe<[SignalAction]> 
        = getSignalActions(desired, actions.fromLeft)
      in
        if sigs.isJust
        then just(\e::Expr loc::Location ->
                heldUnaryActionProd(sys, nm, mangledName, sigs.fromJust,
                                    getObj, innerProd, hostProd, e, 
                                    conds, location=loc)
                )
        else just(\e::Expr loc::Location ->
                errorExpr([err(loc, "This action is not permitted on this object")],
                  location=loc))
      end;
}

function heldBinaryAction
Maybe<ovrld:BinaryProd> ::= unsyncd::Boolean actions::Either<Actions Accesses>
                            getObj::(Expr ::= Expr)
                            innerProd::Maybe<ovrld:BinaryProd>
                            hostProd::ovrld:BinaryProd
                            desired::(Maybe<ActionType> ::= Decorated Expr) 
                            sys::LockSystem nm::Name mangledName::String
                            conds::[Pair<String Pair<Boolean Expr>>]
{
  return
    if unsyncd
    then heldLBinaryOperator(getObj, innerProd, hostProd, sys, nm, mangledName, conds)
    else if actions.isRight
    then just(\lhs::Expr rhs::Expr loc::Location ->
            errorExpr([err(loc, "Actions are not permitted on this object")],
              location=loc))
    else
      just(\lhs::Expr rhs::Expr loc::Location -> 
        heldBinaryActionProd(actions, getObj, innerProd, hostProd, desired,
          sys, nm, mangledName, lhs, rhs, conds, location=loc));
}

function heldArrayAccess
Maybe<ovrld:BinaryProd> ::= unsyncd::Boolean actions::Either<Actions Accesses>
                            getObj::(Expr ::= Expr)
                            innerProd::Maybe<ovrld:BinaryProd>
                            sys::LockSystem nm::Name mangledName::String
                            conds::[Pair<String Pair<Boolean Expr>>]
{
  local prod :: (Expr ::= Expr Expr Location) =
    if innerProd.isJust
    then innerProd.fromJust
    else arraySubscriptExpr(_, _, location=_);

  return 
    just(\arr::Expr idx::Expr loc::Location ->
      if unsyncd
      then produceTypedExpr(prod(getObj(arr), heldCheckOtherSide(idx, location=loc), loc),
            (\t::Type -> heldType(t, t, asRealType(_, t), true, error("Internal error"),
                          sys, nm, mangledName, conds)),
            location=loc)
      else if actions.isLeft
      then errorExpr([err(loc, "Accesses are not allowed on this object")], location=loc)
      else 
        let sVal::Maybe<SynchronizedValue> = 
          getAccessValue(arrayAccess(), actions.fromRight)
        in
          if sVal.isJust
          then produceTypedExpr(prod(getObj(arr), heldCheckOtherSide(idx, location=loc), loc),
                (\t::Type -> heldType(t, t, asRealType(_, t), false, sVal.fromJust.actions,
                                sys, nm, mangledName, conds)),
                location=loc)
          else produceTypedExpr(prod(getObj(arr), heldCheckOtherSide(idx, location=loc), loc),
                (\t::Type -> heldType(t, t, asRealType(_, t), true, error("Internal error"),
                              sys, nm, mangledName, conds)),
                location=loc)
        end);
}

function heldMemberAccess
Maybe<(Expr ::= Expr Boolean Name Location)> ::= unsyncd::Boolean
                                      actions::Either<Actions Accesses>
                                      getObj::(Expr ::= Expr)
                                      innerType::Type sys::LockSystem
                                      nm::Name mangledName::String
                                      conds::[Pair<String Pair<Boolean Expr>>]
{
  return
    just(\e::Expr deref::Boolean fieldName::Name loc::Location ->
      let innerProd :: Maybe<(Expr ::= Expr Name Location)> =
        (decorate innerType with {ovrld:isDeref=deref;}).ovrld:memberProd
      in
      let prod :: (Expr ::= Expr Name Location) =
        if innerProd.isJust
        then innerProd.fromJust
        else memberExpr(_, deref, _, location=_)
      in
      if unsyncd
      then produceTypedExpr(prod(getObj(e), fieldName, loc),
              (\t::Type -> heldType(t, t, asRealType(_, t), true, error("Internal error"),
                            sys, nm, mangledName, conds)),
              location=loc)
      else if actions.isLeft
      then errorExpr([err(loc, "Accesses are not allowed on this object")], location=loc)
      else
        let sVal::Maybe<SynchronizedValue> =
          getAccessValue(memberAccess(fieldName.name, deref), actions.fromRight)
        in
          if sVal.isJust
          then produceTypedExpr(prod(getObj(e), fieldName, loc),
                (\t::Type -> heldType(t, t, asRealType(_, t), false, sVal.fromJust.actions,
                              sys, nm, mangledName, conds)),
                location=loc)
          else produceTypedExpr(prod(getObj(e), fieldName, loc),
                (\t::Type -> heldType(t, t, asRealType(_, t), true, error("Internal error"),
                              sys, nm, mangledName, conds)),
                location=loc)
        end
      end
      end);
}

function heldMemberEqAction
Maybe<(Expr ::= Expr Boolean Name Expr Location)> ::= innerType::Type 
                            hostType::Type getObj::(Expr ::= Expr)
                            unsyncd::Boolean actions::Either<Actions Accesses>
                            sys::LockSystem nm::Name mangledName::String
                            conds::[Pair<String Pair<Boolean Expr>>]
{
  local lhsType :: ExtType = heldType(innerType, hostType, getObj,
                                unsyncd, actions, sys, nm, mangledName, conds);
  lhsType.givenQualifiers = nilQualifier();

  return
    if lhsType.ovrld:memberProd.isJust
    then
      just(\lhs::Expr deref::Boolean fieldName::Name rhs::Expr loc::Location
          -> heldMemberEqProd(lhsType, lhs, deref, fieldName, rhs, location=loc))
    else nothing();
}

abstract production heldMemberEqProd
top::Expr ::= lhsType::ExtType lhs::Expr deref::Boolean fieldName::Name
              rhs::Expr
{
  top.pp = parens(ppConcat([lhs.pp, text(" = "), rhs.pp]));

  local lhsRes :: Expr =
    lhsType.ovrld:memberProd.fromJust(lhs, deref, fieldName, top.location);
  lhsType.givenQualifiers = nilQualifier();
  lhsRes.env = top.env;
  lhsRes.controlStmtContext = top.controlStmtContext;

  local typeEq :: Maybe<ExtType> =
    case lhsRes.typerep of
    | extType(_, eT) -> just(eT)
    | _ -> nothing()
    end;
  local eqType :: ExtType = typeEq.fromJust;
  eqType.givenQualifiers = nilQualifier();
  eqType.ovrld:otherType = rhs.typerep;

  forwards to
    if typeEq.isJust && eqType.ovrld:lEqProd.isJust
    then eqType.ovrld:lEqProd.fromJust(lhsRes, rhs, top.location)
    else errorExpr([err(top.location, "This access is not allowed")],
            location=top.location);
}

function heldDereferenceAccess
Maybe<ovrld:UnaryProd> ::= unsyncd::Boolean actions::Either<Actions Accesses>
                            getObj::(Expr ::= Expr)
                            innerProd::Maybe<ovrld:UnaryProd>
                            sys::LockSystem nm::Name mangledName::String
                            conds::[Pair<String Pair<Boolean Expr>>]
{
  local prod :: (Expr ::= Expr Location) =
    if innerProd.isJust
    then innerProd.fromJust
    else dereferenceExpr(_, location=_);

  return 
    just(\e::Expr loc::Location ->
      if unsyncd
      then produceTypedExpr(prod(getObj(e), loc),
            (\t::Type -> heldType(t, t, asRealType(_, t), true, error("Internal error"),
                          sys, nm, mangledName, conds)),
            location=loc)
      else if actions.isLeft
      then errorExpr([err(loc, "Accesses are not allowed on this object")], location=loc)
      else 
        let sVal::Maybe<SynchronizedValue> = 
          getAccessValue(derefAccess(), actions.fromRight)
        in
          if sVal.isJust
          then produceTypedExpr(prod(getObj(e), loc),
                (\t::Type -> heldType(t, t, asRealType(_, t), false, sVal.fromJust.actions,
                                sys, nm, mangledName, conds)),
                location=loc)
          else produceTypedExpr(prod(getObj(e), loc),
                (\t::Type -> heldType(t, t, asRealType(_, t), true, error("Internal error"),
                              sys, nm, mangledName, conds)),
                location=loc)
        end);
}

abstract production heldUnaryActionProd
top::Expr ::= sys::LockSystem nm::Name mangledName::String sigs::[SignalAction]
              getObj::(Expr ::= Expr) innerProd::Maybe<ovrld:UnaryProd>
              hostProd::ovrld:UnaryProd e::Expr
              conds::[Pair<String Pair<Boolean Expr>>]
{
  top.pp = e.pp;

  forwards to
    stmtExpr(
      produceSignals(sys, top.env, nm, mangledName, sigs),
      heldUnaryOperator(getObj, innerProd, hostProd,
          sys, nm, mangledName, conds)
      .fromJust(e, top.location), location=top.location);
}

abstract production heldBinaryActionProd
top::Expr ::= actions::Either<Actions Accesses> getObj::(Expr ::= Expr)
              innerProd::Maybe<ovrld:BinaryProd> hostProd::ovrld:BinaryProd
              desired::(Maybe<ActionType> ::= Decorated Expr)
              sys::LockSystem nm::Name mangledName::String
              lhs::Expr rhs::Expr conds::[Pair<String Pair<Boolean Expr>>]
{
  top.pp = text("/* heldBinaryActionProd */");

  forwards to
    let desire::Maybe<ActionType> = desired(rhs)
    in
      if desire.isJust
      then
        let sigs::Maybe<[SignalAction]>
          = getSignalActions(desire.fromJust, actions.fromLeft)
        in
          if sigs.isJust
          then stmtExpr(
                  produceSignals(sys, top.env, nm, mangledName, sigs.fromJust),
                  heldLBinaryOperator(getObj, innerProd, hostProd,
                      sys, nm, mangledName, conds).fromJust(lhs, rhs, top.location),
                  location=top.location
                )
          else errorExpr([err(top.location, "This action is not permitted on this object")],
                        location=top.location)
        end 
      else errorExpr([err(top.location, "This action must involve a constant rhs")],
                    location=top.location)
    end;
}

abstract production heldCheckOtherSide
top::Expr ::= e::Expr
{
  top.pp = e.pp;

  forwards to
    case e.typerep of
    | extType(_, heldType(_, _, getObj, _, _, _, _, _, _)) -> getObj(e)
    | _ -> e
    end;
}

abstract production produceRvalExpr
top::Expr ::= e::Expr sys::LockSystem nm::Name mangledName::String
              conds::[Pair<String Pair<Boolean Expr>>]
{
  top.pp = e.pp;

  forwards to
    exprAsType(
      e,
      extType(nilQualifier(),
        heldType(e.typerep, e.typerep, asRealType(_, e.typerep), false, left([]),
            sys, nm, mangledName, conds)
      ),
      location=top.location
    );
}

abstract production produceTypedExpr
top::Expr ::= e::Expr predType::(ExtType ::= Type)
{
  top.pp = e.pp;

  forwards to
    exprAsType(
      e,
      extType(nilQualifier(),
        predType(e.typerep)
      ),
      location=top.location
    );
}

function getSignalActions
Maybe<[SignalAction]> ::= desired::ActionType actions::Actions
{
  return
    case actions of
    | [] -> nothing()
    | pair(act, sigs) :: tl ->
        case act, desired of
        | increaseAction(nothing()), increaseAction(_) -> just(sigs)
        | increaseAction(just(v1)), increaseAction(just(v2)) 
            when v1 == v2 -> just(sigs)
        | decreaseAction(nothing()), decreaseAction(_) -> just(sigs)
        | decreaseAction(just(v1)), decreaseAction(just(v2))
            when v1 == v2 -> just(sigs)
        | setEqAction(v1), setEqAction(v2) when v1 == v2 -> just(sigs)
        | setNeqAction(v1), setEqAction(v2) when v1 != v2 -> just(sigs)
        | _, _ -> getSignalActions(desired, tl)
        end
    end;
}

function getAccessValue
Maybe<SynchronizedValue> ::= desired::AccessType accesses::Accesses
{
  return
    case accesses of
    | [] -> nothing()
    | pair(acc, sVal) :: tl ->
        case acc, desired of
        | memberAccess(n1, a1), memberAccess(n2, a2)
            when n1 == n2 && a1 == a2 -> just(sVal)
        | arrayAccess(), arrayAccess() -> just(sVal)
        | derefAccess(), derefAccess() -> just(sVal)
        | _, _ -> getAccessValue(desired, tl)
        end
    end;
}

function produceSignals
Stmt ::= sys::LockSystem env::Decorated Env nm::Name mangledName::String
          signals::[SignalAction]
{
  local sig::SignalAction = head(signals);
  local isNot :: Boolean =
    case sig of
    | signalIgnore() -> error("Internal error")
    | signalSignal(isNot, _) -> isNot
    | signalBroadcast(isNot, _) -> isNot
    end;
  local varName :: Name =
    case sig of
    | signalIgnore() -> error("Internal error")
    | signalSignal(_, n) -> n
    | signalBroadcast(_, n) -> n
    end;

  sys.env = env;
  sys.condvar = ableC_Expr { 
    ((struct $name{mangledName}*) $Name{nm})->
      $name{"__" ++ (if isNot then "not__" else "") ++ varName.name}
    };

  return 
    if null(signals) then nullStmt()
    else
      case sig of
      | signalIgnore() ->
          seqStmt(nullStmt(), produceSignals(sys, env, nm, mangledName, tail(signals)))
      | signalSignal(_, _) ->
          seqStmt(sys.signalCV, produceSignals(sys, env, nm, mangledName, tail(signals)))
      | signalBroadcast(_, _) ->
          seqStmt(sys.broadcastCV, produceSignals(sys, env, nm, mangledName, tail(signals)))
      end;
}

function heldCheckExprs
Exprs ::= es::Exprs
{
  return
    case es of
    | nilExpr() -> nilExpr()
    | consExpr(h, tl) -> consExpr(heldCheckOtherSide(h, location=h.location),
                            heldCheckExprs(tl))
    end;
}
