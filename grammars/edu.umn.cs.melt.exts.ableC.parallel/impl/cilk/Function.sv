grammar edu:umn:cs:melt:exts:ableC:parallel:impl:cilk;

global MODULE_NAME :: String = "ableC-parallel-cilk";

marking terminal CilkFunc_t 'cilk_func' lexer classes {Keyword, Reserved};

concrete productions top::Declaration_c
| 'cilk_func' d::CilkFunctionDefinition_c {
    top.ast = cilkParFunctionConverter(d.ast);
  }
