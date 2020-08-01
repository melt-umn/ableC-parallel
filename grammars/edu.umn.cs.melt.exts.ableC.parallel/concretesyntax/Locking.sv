grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

concrete productions top::Stmt_c
| 'acquire' locks::NamesList_c ';' {
    top.ast = acquireLocks(locks.ast);
  }
| 'release' locks::NamesList_c ';' {
    top.ast = releaseLocks(locks.ast);
  }
