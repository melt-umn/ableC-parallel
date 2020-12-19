grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel;


-- Attribute for generating the code for when we lift code into a 
-- function to be called for parallel usage
functor attribute forLift occurs on AsmArgument, AsmOperand,
  AsmOperands, AsmClobbers, AsmStatement, Decl, Declarator, Declarators,
  Decls, Expr, Exprs, Init, Initializer, InitList, MaybeExpr,
  MaybeInitializer, Stmt;

propagate forLift on AsmArgument, AsmOperand,
  AsmOperands, AsmClobbers, AsmStatement, Decl, Declarator, Declarators,
  Decls, Expr, Exprs, Init, Initializer, InitList, MaybeExpr,
  MaybeInitializer, Stmt excluding declRefExpr;

aspect production declRefExpr
top::Expr ::= id::Name
{
  top.forLift = 
    case id.valueItem.typerep of
    | extType(_, fakePublicForLift()) -> ableC_Expr { *(args->$Name{id}) }
    | extType(_, fakePrivateForLift()) -> ableC_Expr { args->$Name{id} }
    | _ -> declRefExpr(id, location=top.location)
    end;
}

abstract production fakePublicForLift
top::ExtType ::=
{
  propagate canonicalType;

  top.pp = text("fake type: should not show up");
  top.mangledName = "fake_public_type_never_use";
  top.isEqualTo = \ o::ExtType -> false;
  top.host = errorType();
}

abstract production fakePrivateForLift
top::ExtType ::=
{
  propagate canonicalType;

  top.pp = text("fake type: should not show up");
  top.mangledName = "fake_private_type_never_use";
  top.isEqualTo = \ o::ExtType -> false;
  top.host = errorType();
}
