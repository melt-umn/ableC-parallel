grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax:parallel;

nonterminal ParallelFunctionDecl with pp, env, controlStmtContext, isTopLevel;
abstract production parallelFunctionDecl
top::ParallelFunctionDecl ::= storage::StorageClasses fnquals::SpecialSpecifiers
                              bty::BaseTypeExpr mty::TypeModifierExpr
                              fname::Name attrs::Attributes dcls::Decls body::Stmt
{
  top.pp = ppConcat([terminate(space(), storage.pps),
                    terminate(space(), fnquals.pps),
                    bty.pp, space(), mty.lpp, fname.pp, mty.rpp,
                    ppAttributesRHS(attrs), line(),
                    terminate(cat(semi(), line()), dcls.pps),
                    text("{"), line(), nestlines(2,body.pp), text("}")
                  ]);

  bty.givenRefId = nothing();
  mty.baseType = bty.typerep;
  mty.typeModifierIn = bty.typeModifier;
}

abstract production parallelFunctionProto
top::ParallelFunctionDecl ::= storage::StorageClasses fnquals::SpecialSpecifiers
                              bty::BaseTypeExpr mty::TypeModifierExpr
                              fname::Name attrs::Attributes
{
  top.pp = ppConcat([terminate(space(), storage.pps),
                    terminate(space(), fnquals.pps),
                    bty.pp, space(), mty.lpp, fname.pp, mty.rpp,
                    ppAttributesRHS(attrs), line(), semi()]);

  bty.givenRefId = nothing();
  mty.baseType = bty.typerep;
  mty.typeModifierIn = bty.typeModifier;
}

abstract production parallelFunction
top::Decl ::= interface::Name func::ParallelFunctionDecl
{
  top.pp = ppConcat([text("parallel by"), space(), interface.pp, space(), func.pp]);

  local localErrors :: [Message] =
    case interface.valueLookupCheck of
    | [] ->
      case systemType of
      | extType(_, parallelType(_)) -> []
      | _ -> [err(interface.location, "Cannot create a parallel function from a non parallel-interface value")]
      end
    | errs -> errs
    end;

  local systemType :: Type = interface.valueItem.typerep;
  local sys :: ParallelSystem =
    case systemType of
    | extType(_, parallelType(s)) -> s
    | _ -> error("Bad type reported via errors")
    end;

  forwards to
    if !null(localErrors)
    then warnDecl(localErrors)
    else sys.transFunc(func);
}
  
-- It is pretty common to just translate the parallel function directly to its
-- C form, so we provide a production for that so new implementation can use it
abstract production parallelFuncToC
top::Decl ::= func::ParallelFunctionDecl
{
  forwards to
    case func of
    | parallelFunctionDecl(storage, fnquals, bty, mty, fname, attrs, dcls, body)
      -> functionDeclaration(
          functionDecl(storage, fnquals, bty, mty, fname, attrs, dcls, body))
    | parallelFunctionProto(storage, fnquals, bty, mty, fname, attrs)
      -- Apparently fnquls are ignored, seems weird
      -> variableDecls(
          storage,
          attrs,
          bty,
          consDeclarator(
            declarator(
              fname, mty, attrs, nothingInitializer()
            ),
            nilDeclarator()
          )
        )
    end;
}
