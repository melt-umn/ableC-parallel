grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

concrete productions top::Stmt_c
| 'wait' cvs::NamesList_c ';' {
    top.ast = waitStmt(cvs.ast);
  }
| 'signal' cv::Identifier_c ';' {
    top.ast = signalStmt(cv.ast);
  }
| 'broadcast' cv::Identifier_c ';' {
    top.ast = broadcastStmt(cv.ast);
  }
