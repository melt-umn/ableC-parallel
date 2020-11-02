grammar edu:umn:cs:melt:exts:ableC:parallel:abstractsyntax;

global builtin :: Location = builtinLoc("parallel");

-- An attribute placed on parallelization / locking systmems to unique
-- ID them (this should probably be a fully-qualified name of the extension
-- introducing the system).
synthesized attribute parName::String;
