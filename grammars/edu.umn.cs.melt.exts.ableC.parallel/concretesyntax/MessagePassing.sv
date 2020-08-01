grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

concrete productions top::Expr_c
| 'send' val::Expr_c ':' recipient::Identifier_c {
    top.ast = sendExpr(val.ast, recipient.ast, location=top.location);
  }
| 'receive' {
    top.ast = receiveExpr(nothing(), location=top.location);
  }
| 'receive' source::Identifier_c {
    top.ast = receiveExpr(just(source.ast), location=top.location);
  }
