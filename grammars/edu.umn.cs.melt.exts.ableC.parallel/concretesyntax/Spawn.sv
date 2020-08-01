grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

concrete productions top::Stmt_c
| x::Spawn_t options::SpawnOptions_c stmt::Stmt_c {
    top.ast = spawnStmt(stmt.ast, options.ast);
  }

nonterminal SpawnOptions_c with ast<SpawnOptions>, location;

concrete productions top::SpawnOptions_c
| { top.ast = emptyOptions(); }
| 'by' sys::Identifier_t rest::SpawnOptions_c {
    top.ast = systemOption(sys.lexeme, rest.ast, sys.location);
  }
| 'as' nm::Identifier_t rest::SpawnOptions_c {
    top.ast = nameOption(nm.lexeme, rest.ast, nm.location);
  }
| x::In_t groups::NamesList_c rest::SpawnOptions_c {
    top.ast = groupOption(groups.ast, rest.ast, x.location);
  }
