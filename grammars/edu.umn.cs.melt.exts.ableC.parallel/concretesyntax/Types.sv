grammar edu:umn:cs:melt:exts:ableC:parallel:concretesyntax;

concrete productions top::TypeSpecifier_c
| x::Atomic_t '<' t::TypeName_c '>' {
    top.realTypeSpecifiers=[tempTypeExpr(top.givenQualifiers, top.location)];
    top.preTypeSpecifiers = [];
  }
| x::CondVar_t {
    top.realTypeSpecifiers=[tempTypeExpr(top.givenQualifiers, top.location)];
    top.preTypeSpecifiers = [];
  }
| x::Group_t {
    top.realTypeSpecifiers=[tempTypeExpr(top.givenQualifiers, top.location)];
    top.preTypeSpecifiers = [];
  }
| x::Lock_t {
    top.realTypeSpecifiers=[tempTypeExpr(top.givenQualifiers, top.location)];
    top.preTypeSpecifiers = [];
  }
| x::Messages_t {
    top.realTypeSpecifiers=[tempTypeExpr(top.givenQualifiers, top.location)];
    top.preTypeSpecifiers = [];
  }
| x::Parallel_t {
    top.realTypeSpecifiers=[tempTypeExpr(top.givenQualifiers, top.location)];
    top.preTypeSpecifiers = [];
  }
| x::ParArray_t {
    top.realTypeSpecifiers=[tempTypeExpr(top.givenQualifiers, top.location)];
    top.preTypeSpecifiers = [];
  }
| x::Thread_t {
    top.realTypeSpecifiers=[tempTypeExpr(top.givenQualifiers, top.location)];
    top.preTypeSpecifiers = [];
  }
