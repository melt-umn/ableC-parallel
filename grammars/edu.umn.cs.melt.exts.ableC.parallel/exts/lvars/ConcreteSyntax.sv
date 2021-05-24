grammar edu:umn:cs:melt:exts:ableC:parallel:exts:lvars;

marking terminal LVar_t 'lvar' lexer classes {Keyword, Type, Reserved};
marking terminal Put_t '<-' lexer classes {Assignment};
marking terminal Get_t 'get' lexer classes {Keyword, Reserved};
marking terminal Freeze_t 'freeze' lexer classes {Keyword, Global};

terminal At_t 'at';

concrete productions top::TypeSpecifier_c
| 'lvar' '<' t::TypeName_c '>' {
    top.realTypeSpecifiers = [lvarTypeExpr(top.givenQualifiers, t.ast, top.location)];
    top.preTypeSpecifiers = [];
  }

concrete productions top::AssignOp_c
| '<-' { top.ast = lvarPut(top.leftExpr, top.rightExpr, location=top.exprLocation); }


concrete productions top::Expr_c
| 'freeze' lvar::Expr_c {
    top.ast = lvarFreeze(lvar.ast, location=top.location);
  }
| 'get' id::Identifier_t 'at' func::Expr_c {
    top.ast = lvarGet(
      declRefExpr(name(id.lexeme, location=id.location), location=id.location),
      func.ast, location=top.location);
  }
| 'get' '(' lvar::Expr_c ')' 'at' func::Expr_c {
    top.ast = lvarGet(lvar.ast, func.ast, location=top.location);
  }
