grammar edu:umn:cs:melt:exts:ableC:parallel:exts:synchronization:abstractsyntax;

abstract production synchronizedTypeDecl
top::Decl ::= sys::LockSystem inner::TypeName conds::OptionalConds 
              globals::[Pair<Name Type>] mangledName::String loc::Location
{
  top.pp = text("/* synchronized type generated struct */");

  local cvs :: [Pair<String Boolean>] = conds.condVars;
  local cvItems :: [StructItem] =
    map(\p::Pair<String Boolean> -> 
      structItem(nilAttribute(), directTypeExpr(sys.condType), 
        consStructDeclarator(
          structField(
            name(s"${if p.snd then "" else "__not"}__${p.fst}", location=loc), 
            baseTypeExpr(), nilAttribute()), 
          nilStructDeclarator()
        )
      ),
      cvs
    );

  -- We take each global accessed in the conditions and produce a qualified
  -- name to point to that variable (to handle problems with shadowing of
  -- globals)
  local globalDecl :: [Decl] =
    map(\p::Pair<Name Type> ->
      maybeTagDecl(
        s"__global_${mangledName}_${p.fst.name}",
        ableC_Decl {
          $directTypeExpr{p.snd}* $name{s"__global_${mangledName}_${p.fst.name}"}
            = &$name{p.fst.name};
        }),
      globals);
  local liftedGlobals :: Decl =
    injectGlobalDeclsDecl(foldDecl(globalDecl));

  forwards to
    decls(
      consDecl(
        liftedGlobals,
        consDecl(
          maybeTagDecl(
            mangledName,
            ableC_Decl { struct __attribute__((refId(
              $stringLiteralExpr{s"edu:umn:cs:melt:exts:ableC:parallel:exts:synchronization:${mangledName}"}
            ))) $name{mangledName} {
                $directTypeExpr{inner.typerep} value;
                
                $directTypeExpr{sys.lockType} lck;

                $StructItemList{foldr(consStructItem, nilStructItem(), cvItems)}
              };
            }
          ),
          nilDecl()
        )
      )
    );
}
