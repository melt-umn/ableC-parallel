grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax;

function getReference
Expr ::= e::Decorated Expr
{
  return
    case e.typerep of
    | pointerType(_, _) -> new(e)
    | arrayType(_, _, _, _) -> new(e)
    | _ -> addressOfExpr(new(e), location=e.location)
    end;
}

function getPointerType
Type ::= t::Type
{
  return
    case t of
    | pointerType(_, _) -> t
    | arrayType(_, _, _, _) -> t
    | _ -> pointerType(nilQualifier(), t)
    end;
}

abstract production exprAsType
top::Expr ::= e::Expr t::Type
{
  top.typerep = t;
  forwards to e;
}

function cleanLocName
String ::= inpt::String
{
  return
    substitute("/", "_", 
      substitute(":", "_",
        substitute(".", "_", inpt)
      )
    );
}
