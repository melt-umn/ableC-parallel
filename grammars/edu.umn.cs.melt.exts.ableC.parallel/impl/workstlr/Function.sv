grammar edu:umn:cs:melt:exts:ableC:parallel:impl:workstlr;

global MODULE_NAME :: String = "ableC-parallel-workstlr";

marking terminal WorkstlrFunc_t 'workstlr_func' lexer classes {Keyword, Reserved};

concrete productions top::Declaration_c
| 'workstlr_func' d::CilkFunctionDefinition_c {
    top.ast = workstlrParFunctionConverter(d.ast);
  }
