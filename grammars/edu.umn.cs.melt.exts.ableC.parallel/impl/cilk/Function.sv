grammar edu:umn:cs:melt:exts:ableC:parallel:impl:cilk;

global MODULE_NAME :: String = "ableC-parallel-cilk";

abstract production cilkParFunctionConverter
top::Decl ::= decl::ParallelFunctionDecl
{
  propagate env, controlStmtContext;
  top.pp = ppConcat([text("parallel by cilk"), space(), decl.pp]);
  
  local bty :: Decorated BaseTypeExpr =
    case decl of
    | parallelFunctionDecl(_, _, bty, _, _, _, _, _) -> bty
    | parallelFunctionProto(_, _, bty, _, _, _) -> bty
    end;
  local mty :: Decorated TypeModifierExpr =
    case decl of
    | parallelFunctionDecl(_, _, _, mty, _, _, _, _) -> mty
    | parallelFunctionProto(_, _, _, mty, _, _) -> mty
    end;

  local retMty :: TypeModifierExpr =
    case mty of
    | functionTypeExprWithArgs(r, _, _, _) -> r
    | functionTypeExprWithoutArgs(r, _, _) -> r
    | _ -> error("Other types are not functions")
    end;
  local args :: Parameters =
    case mty of
    | functionTypeExprWithArgs(_, args, _, _) -> args
    | functionTypeExprWithoutArgs(_, _, _) -> nilParameters()
    | _ -> error("Other types are not functions")
    end;
  local retType :: Type = (decorate retMty with {baseType=bty.typerep; typeModifierIn=baseTypeExpr();
      env=top.env; controlStmtContext=initialControlStmtContext;}).typerep;

  forwards to
    case decl of
    | parallelFunctionDecl(storage, fnquals, bty, mty, fname, attrs, dcls, body)
      -> decls(
          consDecl(
            decls(foldDecl(map(\d::Decorated Decl -> new(d), body.globalDecls))),
            consDecl(
              functionDeclaration(
                functionDecl(storage, fnquals, bty, mty, fname, attrs, dcls,
                  ableC_Stmt {
                    fprintf(stderr, $stringLiteralExpr{s"Directly called ${fname.name} rather than invoking it through a cilk-spawn"});
                    exit(25);
                  }
                )
              ),
              consDecl(
                cilkFunctionDecl(storage, fnquals, bty, mty,
                  name("_cilk_" ++ fname.name, location=fname.location),
                  attrs, dcls, body.cilkVersion),
                nilDecl()
              )
            )
          )
        )
    | parallelFunctionProto(storage, fnquals, bty, mty, fname, attrs)
      -> decls(
          consDecl(
            ableC_Decl { $directTypeExpr{retType} $Name{fname}($Parameters{args}) ; },
            consDecl(
              cilkFunctionProto(storage, fnquals, bty, mty,
                name("_cilk_" ++ fname.name, location=fname.location), attrs),
              nilDecl()
            )
          )
        )
    end;
}
