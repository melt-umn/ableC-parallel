grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

concrete productions top::ExternalDeclaration_c
| 'parallel' 'by' id::Identifier_c func::ParallelFunctionDefinition_c {
    top.ast = parallelFunction(id.ast, func.ast);
  }

closed nonterminal ParallelFunctionDefinition_c with location, ast<ParallelFunctionDecl>;
concrete productions top::ParallelFunctionDefinition_c
| d::ParallelInitialFunctionDefinition_c s::CompoundStatement_c {
    top.ast = d.ast;
    d.givenStmt = s.ast;
  } action {
    context = closeScope(context); -- Opened by InitialFunctionDefinition.
  }
| ds::DeclarationSpecifiers_c d::Declarator_c ';' {
    ds.givenQualifiers = ds.typeQualifiers;
    d.givenType = baseTypeExpr();
    local bt :: BaseTypeExpr =
      figureOutTypeFromSpecifiers(ds.location, ds.typeQualifiers, ds.preTypeSpecifiers, ds.realTypeSpecifiers, ds.mutateTypeSpecifiers);

    local specialSpecifiers :: SpecialSpecifiers =
      foldr(consSpecialSpecifier, nilSpecialSpecifier(), ds.specialSpecifiers);

    top.ast =
      parallelFunctionProto(
        foldStorageClass(ds.storageClass), specialSpecifiers, bt, d.ast,
        d.declaredIdent, ds.attributes
      );
  }

closed nonterminal ParallelInitialFunctionDefinition_c with location, ast<ParallelFunctionDecl>, givenStmt;
concrete productions top::ParallelInitialFunctionDefinition_c
| ds::DeclarationSpecifiers_c  d::Declarator_c  l::InitiallyUnqualifiedDeclarationList_c
    {
      ds.givenQualifiers = ds.typeQualifiers;
      d.givenType = baseTypeExpr();
      l.givenQualifiers =
        case baseMT of
        | functionTypeExprWithArgs(t, p, v, q) -> q
        | functionTypeExprWithoutArgs(t, v, q) -> q
        | _ -> nilQualifier()
        end;

      local specialSpecifiers :: SpecialSpecifiers =
        foldr(consSpecialSpecifier, nilSpecialSpecifier(), ds.specialSpecifiers);
      
      local bt :: BaseTypeExpr =
        figureOutTypeFromSpecifiers(ds.location, ds.typeQualifiers, ds.preTypeSpecifiers, ds.realTypeSpecifiers, ds.mutateTypeSpecifiers);
      
      -- If this is a K&R-style declaration, attatch any function qualifiers to the first declaration instead
      local baseMT  :: TypeModifierExpr = d.ast;
      baseMT.baseType = errorType();
      baseMT.typeModifierIn = baseTypeExpr();
      baseMT.controlStmtContext = initialControlStmtContext;
      local mt :: TypeModifierExpr =
        case l.isDeclListEmpty, baseMT of
        | false, functionTypeExprWithArgs(t, p, v, q) ->
            functionTypeExprWithArgs(t, p, v, nilQualifier())
        | false, functionTypeExprWithoutArgs(t, v, q) ->
            functionTypeExprWithoutArgs(t, v, nilQualifier())
        | _, mt -> mt
        end;

      top.ast =
        parallelFunctionDecl(foldStorageClass(ds.storageClass), specialSpecifiers, bt, mt, d.declaredIdent, ds.attributes, foldDecl(l.ast), top.givenStmt);
    }
    action {
      -- Function are annoying because we have to open a scope, then add the
      -- parameters, and close it after the brace.
      context = beginFunctionScope(d.declaredIdent, Identifier_t, d.declaredParamIdents, Identifier_t, context);
    }
| d::Declarator_c  l::InitiallyUnqualifiedDeclarationList_c
    {
      d.givenType = baseTypeExpr();
      l.givenQualifiers =
        case baseMT of
        | functionTypeExprWithArgs(t, p, v, q) -> q
        | functionTypeExprWithoutArgs(t, v, q) -> q
        | _ -> nilQualifier()
        end;
      
      local bt :: BaseTypeExpr =
        figureOutTypeFromSpecifiers(d.location, nilQualifier(), [], [], []);
      
      -- If this is a K&R-style declaration, attatch any function qualifiers to the first declaration instead
      local baseMT  :: TypeModifierExpr = d.ast;
      baseMT.baseType = errorType();
      baseMT.typeModifierIn = baseTypeExpr();
      baseMT.controlStmtContext = initialControlStmtContext;
      local mt :: TypeModifierExpr =
        case l.isDeclListEmpty, baseMT of
        | false, functionTypeExprWithArgs(t, p, v, q) ->
            functionTypeExprWithArgs(t, p, v, nilQualifier())
        | false, functionTypeExprWithoutArgs(t, v, q) ->
            functionTypeExprWithoutArgs(t, v, nilQualifier())
        | _, mt -> mt
        end;

      top.ast =
        parallelFunctionDecl(nilStorageClass(), nilSpecialSpecifier(), bt, mt, d.declaredIdent, nilAttribute(), foldDecl(l.ast), top.givenStmt);
    }
    action {
      -- Unfortunate duplication. This production is necessary for K&R compatibility
      -- We can't make it a proper optional nonterminal, since that requires a reduce far too early.
      -- (i.e. LALR conflicts)
      context = beginFunctionScope(d.declaredIdent, Identifier_t, d.declaredParamIdents, Identifier_t, context);
    }

