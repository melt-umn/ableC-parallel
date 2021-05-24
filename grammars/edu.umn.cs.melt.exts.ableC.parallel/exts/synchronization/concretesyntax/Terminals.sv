grammar edu:umn:cs:melt:exts:ableC:parallel:exts:synchronization:concretesyntax;

marking terminal Synchronized_t 'synchronized' lexer classes {Keyword, Type, Reserved};
marking terminal Holding_t 'holding' lexer classes {Keyword, Reserved};
marking terminal Wait_t 'wait' lexer classes {Keyword, Reserved};

terminal As_t 'as';

terminal While_t 'while';
terminal Until_t 'until';

terminal Condition_t 'condition';

terminal When_t 'when';
terminal Inc_t 'inc';
terminal Dec_t 'dec';
terminal Mod_t 'mod';
terminal Then_t 'then';
terminal Signal_t 'signal';
terminal Broadcast_t 'broadcast';
terminal Ignore_t 'ignore';
terminal Not_t 'not' lexer classes {Keyword, Reserved};

terminal Underscore_t '_';

terminal DecSignConstant_t /[+\-]?((0)|([1-9][0-9]*))/;
