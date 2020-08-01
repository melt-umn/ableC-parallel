grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

concrete productions top::Stmt_c
| 'sync' names::NamesList_c ';' {
    top.ast = syncStmt(names.ast);
  }
