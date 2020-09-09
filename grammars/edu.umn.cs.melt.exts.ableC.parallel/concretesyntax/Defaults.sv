grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

concrete productions top::Declaration_c
| 'parallel' 'default' feature::ParallelFeature_c sys::Identifier_c ';' {
    top.ast = defaultDeclaration(feature.ast, sys.ast);
  }

closed nonterminal ParallelFeature_c with ast<ParallelFeature>;
concrete productions top::ParallelFeature_c
| x::SpawnFeature_t    { top.ast = featureSpawn();    }
| x::AtomicFeature_t   { top.ast = featureAtomic();   }
| x::ParArrayFeature_t { top.ast = featureParallel(); }
