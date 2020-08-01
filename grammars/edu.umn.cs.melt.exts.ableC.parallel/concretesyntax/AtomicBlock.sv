grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

concrete productions top::Stmt_c
| x::Atomic_t body::Stmt_c {
    top.ast = atomicStmt([], body.ast);
  }
| x::Atomic_t 'with' locks::NamesList_c body::Stmt_c {
    top.ast = atomicStmt(locks.ast, body.ast);
  }
