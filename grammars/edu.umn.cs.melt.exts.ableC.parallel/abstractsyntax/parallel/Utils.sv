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

-- Utilities for cleaning statements and expressions (removing extra brackets
-- and parentheses)
function cleanStmt
Stmt ::= s::Stmt env::Decorated Env
{
  s.controlStmtContext = initialControlStmtContext;
  s.env = env;

  return
    case s of
    | exprStmt(e) -> exprStmt(cleanExpr(e, env))
    | ableC_Stmt { { $Stmt{i} } } -> cleanStmt(i, env)
    | _ -> s
    end;
}

function cleanExpr
Expr ::= e::Expr env::Decorated Env
{
  e.controlStmtContext = initialControlStmtContext;
  e.env = env;

  return
    case e of
    | ableC_Expr { ( $Expr{i} ) } -> cleanExpr(i, env)
    | _ -> e
    end;
}

-- Convert parallel annotations to spawn annotations
synthesized attribute parToSpawnAnnt :: Maybe<SpawnAnnotation> occurs on ParallelAnnotation;
synthesized attribute parToSpawnAnnts :: SpawnAnnotations occurs on ParallelAnnotations;

aspect production consParallelAnnotations
top::ParallelAnnotations ::= hd::ParallelAnnotation tl::ParallelAnnotations
{
  top.parToSpawnAnnts =
    if hd.parToSpawnAnnt.isJust
    then consSpawnAnnotations(hd.parToSpawnAnnt.fromJust, tl.parToSpawnAnnts)
    else tl.parToSpawnAnnts;
}

aspect production nilParallelAnnotations
top::ParallelAnnotations ::=
{
  top.parToSpawnAnnts = nilSpawnAnnotations();
}

aspect default production
top::ParallelAnnotation ::=
{
  top.parToSpawnAnnt = nothing();
}

aspect production parallelByAnnotation
top::ParallelAnnotation ::= expr::Expr
{
  top.parToSpawnAnnt = just(spawnByAnnotation(expr, location=top.location));
}

aspect production parallelInAnnotation
top::ParallelAnnotation ::= group::Expr
{
  top.parToSpawnAnnt = just(spawnInAnnotation(group, location=top.location));
}

aspect production parallelPublicAnnotation
top::ParallelAnnotation ::= ids::[Name]
{
  top.parToSpawnAnnt = just(spawnPublicAnnotation(ids, location=top.location));
}

aspect production parallelPrivateAnnotation
top::ParallelAnnotation ::= ids::[Name]
{
  top.parToSpawnAnnt = just(spawnPrivateAnnotation(ids, location=top.location));
}

aspect production parallelGlobalAnnotation
top::ParallelAnnotation ::= ids::[Name]
{
  top.parToSpawnAnnt = just(spawnGlobalAnnotation(ids, location=top.location));
}
