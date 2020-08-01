grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

-- Terminals for types
marking terminal CondVar_t 'condvar' lexer classes {Type, Global};
marking terminal Group_t 'group' lexer classes {Type, Global};
marking terminal Lock_t 'lock' lexer classes {Type, Global};
marking terminal Messages_t 'messages' lexer classes {Type, Global};
marking terminal Parallel_t 'parallel' lexer classes {Type, Global};
marking terminal ParArray_t 'parArray' lexer classes {Type, Global};
marking terminal Thread_t 'thread' lexer classes {Type, Global};
marking terminal Atomic_t 'atomic' lexer classes {Type, Global};

-- Terminals for feature defaults
terminal SpawnFeature_t 'spawn';
terminal LockFeature_t 'lock';
terminal AtomicFeature_t 'atomic';
terminal ParArrayFeature_t 'parArray';

-- Spawn & Sync
marking terminal Spawn_t 'spawn' lexer classes {Keyword, Reserved};
marking terminal Sync_t  'sync'  lexer classes {Keyword, Reserved};

-- Terminals for spawn options
terminal By_t 'by' lexer classes {Keyword, Reserved};
terminal As_t 'as' lexer classes {Keyword, Reserved};
terminal In_t 'in' lexer classes {Keyword, Reserved};

-- Thread Management
marking terminal This_t 'this' lexer classes {Keyword, Reserved};
marking terminal Parent_t 'parent' lexer classes {Keyword, Reserved};
marking terminal Finish_t 'finish' lexer classes {Keyword, Reserved};

-- Locking Mechanisms
marking terminal Acquire_t 'acquire' lexer classes {Keyword, Reserved};
marking terminal Release_t 'release' lexer classes {Keyword, Reserved};

-- Condition Variables
marking terminal Wait_t 'wait' lexer classes {Keyword, Reserved};
marking terminal Signal_t 'signal' lexer classes {Keyword, Reserved};
marking terminal Broadcast_t 'broadcast' lexer classes {Keyword, Reserved};

-- Message Passing
marking terminal Send_t 'send' lexer classes {Keyword, Reserved};
marking terminal Receive_t 'receive' lexer classes {Keyword, Reserved};

terminal From_t 'from';

-- Atomic Blocks
terminal With_t 'with' lexer classes {Keyword, Reserved};
