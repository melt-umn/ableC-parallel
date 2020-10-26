grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:loop;

synthesized attribute parLoopVarErrs :: [Message] occurs on Decl;

-- Name of the loop variable (extracted from the declaration)
synthesized attribute parLoopVar :: Maybe<Name> occurs on Decl;
-- Initialization value of the loop variable (extracted from the declaration)
synthesized attribute parLoopInit :: Maybe<Expr> occurs on Decl;

aspect default production
top::Decl ::=
{
  top.parLoopVar = nothing();
  top.parLoopInit = nothing();
  top.parLoopVarErrs = [err(builtin, "Parallel for-loop must include a declaration and initialization of its loop variable")];
}

aspect production variableDecls
top::Decl ::= storage::StorageClasses attrs::Attributes ty::BaseTypeExpr dcls::Declarators
{
  top.parLoopVar = 
    if ty.typerep.isIntegerType
    then
      case dcls of
      | consDeclarator(
          declarator(nm, _, _, _),
          nilDeclarator()) -> just(nm)
      | _ -> nothing()
      end
    else nothing();

  top.parLoopInit =
    case dcls of
    | consDeclarator(
        declarator(_, _, _, intz),
        _) -> case intz of
              | justInitializer(exprInitializer(e)) -> just(e)
              | _ -> nothing()
              end
    | _ -> nothing()
    end;

  top.parLoopVarErrs = 
    (if !ty.typerep.isIntegerType
     then [err(builtin, "Loop variable of parallel for-loop must have integer type")]
     else [])
    ++ 
    (case dcls of
     | consDeclarator(dcl, nilDeclarator()) -> 
        case dcl of
        | declarator(_, tm, _, intz) ->
          case tm of
          | baseTypeExpr() ->
            case intz of
            | justInitializer(_) -> []
            | nothingInitializer() -> 
              [err(builtin, "Initialization required for loop variable of parallel for-loop")]
            end
          | _ -> [err(builtin, "Loop variable of a parallel-for loop must have an integer type")]
          end
        | _ -> [err(builtin, "Error in parallel-for loop variable declaration")]
        end
     | _ -> [err(builtin, "Parallel for-loop must declare a single loop variable")]
     end);
}

aspect production decDecl
top::Decl ::= d::Decorated Decl
{
  top.parLoopVar = d.parLoopVar;
  top.parLoopInit = d.parLoopInit;
  top.parLoopVarErrs = d.parLoopVarErrs;
}

aspect production autoDecl
top::Decl ::= n::Name e::Expr
{
  top.parLoopVar = just(n);
  top.parLoopInit = just(e);
  top.parLoopVarErrs = 
    if !e.typerep.isIntegerType
    then [err(builtin, "Loop variable of parallel for-loop must have integer type")]
    else [];
}
