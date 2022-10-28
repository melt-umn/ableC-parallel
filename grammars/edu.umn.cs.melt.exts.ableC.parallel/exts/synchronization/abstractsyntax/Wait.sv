grammar edu:umn:cs:melt:exts:ableC:parallel:exts:synchronization:abstractsyntax;

function lookupCondition
Maybe<Expr> ::= name::String isNot::Boolean conds::[Pair<String Pair<Boolean Expr>>]
{
  return
    case conds of
    | [] -> nothing()
    | pair(s, pair(b, e)) :: tl ->
        if (s == name) && (b == isNot)
        then just(e)
        else lookupCondition(name, isNot, tl)
    end;
}

abstract production waitWhile
top::Stmt ::= ex::Expr
{
  forwards to genericWait(ex, "while", false);
}

abstract production waitUntil
top::Stmt ::= ex::Expr
{
  forwards to genericWait(ex, "until", true);
}

abstract production genericWait
top::Stmt ::= ex::Expr name::String negateCond::Boolean
{
  top.pp = ppConcat([text("wait"), space(), text(name), space(), ex.pp]);
  top.functionDefs := [];
  top.labelDefs := [];

  local localErrors :: [Message] =
    case ex of
    | ableC_Expr { $Name{e} . $Name{n} } ->
        case e.valueItem.typerep of
        | extType(_, heldType(_, _, _, _, _, _, _, _, _)) ->
            if condExpr.isJust
            then []
            else [err(ex.location, s"The condition '${condName}' is not defined for use with ${name}")]
        | _ -> [err(ex.location, "wait expected value to be a held variable")]
        end
    | _ -> [err(ex.location, "wait expected value of form heldVar.condition")]
    end;

  local heldVar :: Name =
    case ex of
    | ableC_Expr { $Name{e} . $Name{_} } -> e
    | _ -> error("Internal error, check errors before forward tree")
    end;
  heldVar.env = top.env;
  
  local condName :: String =
    case ex of
    | ableC_Expr { $Expr{_} . $Name{n} } -> n.name
    | _ -> error("Internal error, check errors before forward tree")
    end;
  local conds :: [Pair<String Pair<Boolean Expr>>] =
    case heldVar.valueItem.typerep of
    | extType(_, heldType(_, _, _, _, _, _, _, _, c)) -> c
    | _ -> error("Internal error, check errors before forward tree")
    end;
  local sys :: LockSystem =
    case heldVar.valueItem.typerep of
    | extType(_, heldType(_, _, _, _, _, s, _, _, _)) -> s
    | _ -> error("Internal error, check errors before forward tree")
    end;
  local mangledName :: String =
    case heldVar.valueItem.typerep of
    | extType(_, heldType(_, _, _, _, _, _, _, m, _)) -> m
    | _ -> error("Internal error, check errors before forward tree")
    end;
  local cvName :: String =
    if negateCond then s"__${condName}" else s"__not__${condName}";

  sys.env = top.env;
  sys.condvar = ableC_Expr { 
    ((struct $name{mangledName}*) $Name{heldVar})->$name{cvName}
  };

  local condExpr :: Maybe<Expr> = lookupCondition(condName, negateCond, conds);
  local conditionExpr :: Expr = 
    let cond::Expr = (decorate condExpr.fromJust with {env=top.env;
              thisName=pair(heldVar, mangledName);
              controlStmtContext=top.controlStmtContext;}).replaceThis
    in
      if negateCond
      then notExpr(cond, location=ex.location)
      else cond
    end;

  forwards to
    if !null(localErrors)
    then warnStmt(localErrors)
    else
      ableC_Stmt {
        {
          while ($Expr{conditionExpr}) {
            $Stmt{sys.waitCV}
          }
        }
      };
}

inherited attribute thisName :: Pair<Name String> occurs on Expr;
functor attribute replaceThis occurs on Expr;
propagate replaceThis on Expr excluding declRefExpr;

aspect production declRefExpr
top::Expr ::= id::Name
{
  top.replaceThis = if id.name == "this"
                    then ableC_Expr { ((struct $name{top.thisName.snd}*) 
                                        $Name{top.thisName.fst})->value }
                    else top;
}
