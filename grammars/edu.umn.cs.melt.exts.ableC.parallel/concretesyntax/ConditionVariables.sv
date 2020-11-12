grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

concrete productions top::Stmt_c
| 'wait' cv::Expr_c ';' { top.ast = waitCV(cv.ast); }
| 'signal' cv::Expr_c ';' { top.ast = signalCV(cv.ast); }
| 'broadcast' cv::Expr_c ';' { top.ast = broadcastCV(cv.ast); }

concrete productions top::TypeSpecifier_c
| 'condvar' {
    top.realTypeSpecifiers = [condvarTypeExpr(top.givenQualifiers)];
    top.preTypeSpecifiers = [];
  }
