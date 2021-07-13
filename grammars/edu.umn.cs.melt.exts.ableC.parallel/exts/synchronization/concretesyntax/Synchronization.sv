grammar edu:umn:cs:melt:exts:ableC:parallel:exts:synchronization:concretesyntax;

concrete productions top::TypeSpecifier_c
| 'synchronized' '<' t::TypeName_c '>' sync::OptionalConds_c {
  top.realTypeSpecifiers = [synchronizationTypeExpr(top.givenQualifiers, 
    t.ast, sync.ast, top.location)];
  top.preTypeSpecifiers = [];
}

nonterminal OptionalConds_c with location, ast<OptionalConds>;
concrete productions top::OptionalConds_c
| { top.ast = noConds(location=top.location); } 
| '=' '{' conds::Conditions_c sigs::Signals_c '}' { 
    top.ast = withConds(conds.ast, sigs.ast, location=top.location);  
  }

nonterminal Conditions_c with location, ast<Conditions>;
concrete productions top::Conditions_c
| { top.ast = nilCondition(); }
| h::Condition_c t::Conditions_c { top.ast = consCondition(h.ast, t.ast); }

nonterminal Condition_c with location, ast<Condition>;
concrete productions top::Condition_c
| 'condition' id::Identifier_c '(' ex::Expr_c ')' ';' { 
    top.ast = condition(id.ast, ex.ast);
  }

nonterminal Signals_c with location, ast<Signals>;
concrete productions top::Signals_c
| { top.ast = nilSignal(); }
| h::Signal_c t::Signals_c { top.ast = consSignal(h.ast, t.ast); }

nonterminal Signal_c with location, ast<Signal>;
concrete productions top::Signal_c
| 'when' '(' e::Expr_c ')' mod::ModAction_c 'then' act::SignalAction_c ';' {
    top.ast = signal(e.ast, mod.ast, act.ast, location=top.location);
  }

-- We only allow positive numbers for +=/-= to enforce that += is intended to
-- mean an increase and -= is intended to mean a decrease. For =/!= we also
-- allow negative values (using the DecSignConstant_t terminal)
nonterminal ModAction_c with location, ast<ModAction>;
concrete productions top::ModAction_c
| '+=' val::DecConstant_t { top.ast = modIncrease(just(toInteger(val.lexeme))); }
| '+=' '_' { top.ast = modIncrease(nothing()); }
| '-=' val::DecConstant_t { top.ast = modDecrease(just(toInteger(val.lexeme))); }
| '-=' '_' { top.ast = modDecrease(nothing()); }
| '=' val::DecSignConstant_t { top.ast = modEquals(toInteger(val.lexeme)); }
| '!=' val::DecSignConstant_t { top.ast = modNotEquals(toInteger(val.lexeme)); }

nonterminal SignalAction_c with location, ast<SignalAction>;
concrete productions top::SignalAction_c
| 'ignore' { top.ast = signalIgnore(); }
| 'signal' id::Identifier_t { 
    top.ast = signalSignal(false, name(id.lexeme, location=top.location)); 
  }
| 'signal' 'not' id::Identifier_t { 
    top.ast = signalSignal(true, name(id.lexeme, location=top.location)); 
  }
| 'broadcast' id::Identifier_t { 
    top.ast = signalBroadcast(false, name(id.lexeme, location=top.location));
  }
| 'broadcast' 'not' id::Identifier_t { 
    top.ast = signalBroadcast(true, name(id.lexeme, location=top.location));
  }
