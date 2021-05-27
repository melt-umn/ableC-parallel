grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

marking terminal Parallel_t 'parallel' lexer classes {Keyword, Type, Reserved};

marking terminal Spawn_t 'spawn' lexer classes {Keyword, Reserved};
marking terminal Sync_t 'sync' lexer classes {Keyword, Reserved};

marking terminal Lock_t 'lock' lexer classes {Type, Global};
marking terminal Condvar_t 'condvar' lexer classes {Type, Global};
marking terminal Thread_t 'thread' lexer classes {Type, Global};
marking terminal Group_t 'group' lexer classes {Type, Global};

marking terminal Acquire_t 'acquire' lexer classes {Keyword, Global};
marking terminal Release_t 'release' lexer classes {Keyword, Global};

marking terminal Wait_t 'wait' lexer classes {Keyword, Reserved};
marking terminal Signal_t 'signal' lexer classes {Keyword, Global};
marking terminal Broadcast_t 'broadcast' lexer classes {Keyword, Global};


-- Annotations
terminal By_t 'by' lexer classes {Keyword, Reserved};

terminal As_t 'as' lexer classes {Keyword, Reserved};
terminal In_t 'in' lexer classes {Keyword, Reserved};

terminal Private_t 'private' lexer classes {Keyword, Reserved};
terminal Public_t  'public'  lexer classes {Keyword, Reserved};
terminal Global_t  'global'  lexer classes {Keyword, Reserved};

terminal NumThreads_t 'num-threads' lexer classes {Keyword, Reserved};
