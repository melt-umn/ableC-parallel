grammar edu:umn:cs:melt:exts:ableC:parallel:exts:mapReduce;

functor attribute variableReplaced occurs on AsmArgument, AsmOperand,
  AsmOperands, AsmClobbers, AsmStatement, Decl, Declarator, Declarators,
  Decls, Expr, Exprs, Init, Initializer, InitList, MaybeExpr,
  MaybeInitializer, Stmt;
propagate variableReplaced on AsmArgument, AsmOperand,
  AsmOperands, AsmClobbers, AsmStatement, Decl, Declarator, Declarators,
  Decls, Expr, Exprs, Init, Initializer, InitList, MaybeExpr,
  MaybeInitializer, Stmt excluding declRefExpr;

aspect production declRefExpr
top::Expr ::= id::Name
{
  top.variableReplaced =
    case id.valueItem.typerep of
    | extType(_, replaceVariable(e)) -> e
    | _ -> top
    end;
}

abstract production replaceVariable
top::ExtType ::= e::Expr
{
  propagate canonicalType;

  top.pp = text("fake type: should not show up");
  top.mangledName = "fake_type_replace_var";
  top.isEqualTo = \o::ExtType -> false;
  top.host = errorType();
}

function replaceExprVariable
Expr ::= e::Expr var::Name repl::Expr env::Decorated Env cscx::ControlStmtContext
{
  local replEnv :: Decorated Env =
    addEnv(
      valueDef(
        var.name,
        declaratorValueItem(
          decorate
            declarator(var, baseTypeExpr(), nilAttribute(), nothingInitializer())
          with {
            env=env; baseType=extType(nilQualifier(), replaceVariable(repl));
            typeModifierIn=baseTypeExpr(); givenStorageClasses=nilStorageClass();
            givenAttributes=nilAttribute(); isTopLevel=false; isTypedef=false;
            controlStmtContext=cscx;
          }
        )
      ) :: [],
      env
    );

  e.env = replEnv;
  e.controlStmtContext = cscx;
  return e.variableReplaced;
}
