grammar edu:umn:cs:melt:exts:ableC:parallel:impl:cilk;

global MODULE_NAME :: String = "ableC-parallel-cilk";

marking terminal CilkFunc_t 'cilk_func' lexer classes {Keyword, Reserved};

concrete productions top::Declaration_c
| 'cilk_func' d::CilkFunctionDefinition_c {
    top.ast = cilkParFunctionConverter(d.ast);
  }

abstract production cilkParFunctionConverter
top::Decl ::= decl::Decl
{
  top.pp = ppConcat([text("cilk_func"), space(), decl.pp]);

  local bty :: Decorated BaseTypeExpr =
    case decl of
    | cilkFunctionDecl(_, _, bty, _, _, _, _, _) -> bty
    | cilkFunctionProto(_, _, bty, _, _, _) -> bty
    | _ -> error("Decl must be a function based on concrete syntax")
    end;
  local mty :: Decorated TypeModifierExpr =
    case decl of
    | cilkFunctionDecl(_, _, _, mty, _, _, _, _) -> mty
    | cilkFunctionProto(_, _, _, mty, _, _) -> mty
    | _ -> error("Decl must be a function based on concrete syntax")
    end;

  local retMty :: TypeModifierExpr =
    case mty of
    | functionTypeExprWithArgs(r, _, _, _) -> r
    | functionTypeExprWithoutArgs(r, _, _) -> r
    | _ -> error("Decl must be a function based on concrete syntax")
    end;
  local args :: Parameters =
    case mty of
    | functionTypeExprWithArgs(_, args, _, _) -> args
    | functionTypeExprWithoutArgs(_, _, _) -> nilParameters()
    | _ -> error("Decl must be a function based on concrete syntax")
    end;
  local retType :: Type = (decorate retMty with {baseType=bty.typerep; typeModifierIn=baseTypeExpr();
      env=top.env; controlStmtContext=initialControlStmtContext;}).typerep;

  forwards to
    case decl of
    | cilkFunctionDecl(storage, fnquals, bty, mty, fname, attrs, dcls, body)
      -> decls(
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
    | cilkFunctionProto(storage, fnquals, bty, mty, fname, attrs)
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
    | _ -> error("Concrete syntax above will always produce one of these cases")
    end;
}
