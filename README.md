# An Extensible Parallel Programming Framework for ableC
This extension provides implementation-agnostic syntax and back-end support for
for various parallel programming tools. It also contains several implementations
(which are included here for compactness but are independent extensions) as well
as some extensions built on top of this system (which again are independent
extensions).

## Building New Implementations
There are four pieces of this system that are extensible, allowing new
implementations to be added: parallelism (task spawning and parallel for-loops),
memory synchronization (locks and condition variables), task synchronization
(threads, groups, and `sync`), and balancers.

### Parallelization
The implementations of task spawning and parallel for-loops are specified using
the `ParallelSystem` nonterminal (defined
[here](grammars/edu.umn.cs.melt.exts.ableC.parallel/abstractsyntax/parallel/ParallelSystemDef.sv))
which has six attributes that must be defined:
* `parName :: String`: This attribute just provides a name of the
  implementation, this is used for issuing and looking up unique id numbers to
  each system
* `newProd :: Maybe<(Expr ::= Exprs Location)>`: This attribute provides the
  implementation of `new` for this parallel interface; this is attribute will
  provide initialization code, such as creating the workers for a thread pool
  or work-stealer
* `deleteProd :: Maybe<(Stmt ::= Expr)>`: This attribute provides the
  implementation of `delete` for this parallel interface; this must provide
  shutdown behavior, which should initiate the shutdown of any
  worker-threads
* `fSpawn :: (Stmt ::= Expr Location SpawnAnnotations)`: This attribute provides
  the implementation of spawn, the first argument is the expression being
  spawned
* `fFor :: (Stmt ::= Stmt Location ParallelAnnotations)`: This attribute
  provides the implementation of a parallel for-loop, the first argument is
  the normalized for-loop to be parallelized
* `transFunc :: (Decl :: ParallelFunctionDecl)`: This attribute provides for
  translation of functions (this is used mostly by work-stealers, but can be
  used by any system). If there is no interesting translation needed, the
  production `parallelFuncToC`, provided by ableC parallel, can be used.

### Memory Synchronization
The implementation of locks and condition variables are specified using the
`LockSystem` nonterminal (defined
[here](grammars/edu.umn.cs.melt.exts.ableC.parallel/abstractsyntax/locks/LockSystemDefs.sv))
which has a number of attributes that must be defined. Note that also `env` is
an inherited attribute on this nonterminal and there are two other inherited
attributes: `locks :: [Expr]` and `condvar :: Expr` which are used to provide
a list of locks or a condition variable to the nonterminal, which are then
used by several attributes (as these are defined in that way rather than using
lambdas):
* `parName :: String`: Like in parallelism, provides a name for each
  implementation, and used in a few places to determine whether locks and
  condition variables have the same implementation
* `lockType :: Type`: The C type to give to locks (may depend on `env`)
* `acquireLocks :: Stmt`: Acquires the set of provided locks (via `locks`)
* `releaseLocks :: Stmt`: Releases the set of provided locks (via `locks`)
* `condType :: Type`: The C type to give to condition variables (may depend
  on `env`)
* `waitCV :: Stmt`: Performs a wait on the provided condition variable (via
  `condvar`)
* `signalCV :: Stmt`: Signals the provided condition variable
* `broadcastCV :: Stmt`: Broadcasts on the provided condition variable
* `initializeLock :: (Expr ::= Expr Exprs Location)`: Used to initialize a lock,
  the first argument is the left-hand side (we use initialization in this way,
  rather than directly using `new` because the POSIX implementation requires
  a function call with a pointer to the lock to initialize.
* `lockDeleteProd :: Maybe<(Stmt ::= Expr)>`: Implementation of `delete` for a
  lock
* `initializeCondvar :: (Expr ::= Expr Exprs Location)`: Initializes a
  condition variable, again the first argument is the left-hand side (for the
  same reasons as this is done on locks)
* `condvarDeleteProd :: Maybe<(Stmt ::= Expr)>`: Implementation of `delete` for
  a condition variable

### Task Synchronization
The implementation of task synchronization is specified using the
`SyncSystem` nonterminal (defined
[here](grammars/edu.umn.cs.melt.exts.ableC.parallel/abstractsyntax/sync/SyncSystemDefs.sv))
which has a number of attributes which must be defined. Note that, like with
memory synchronization, `env` is provided on this nonterminal which can be used
and there are `threads :: [Expr]` and `groups :: [Expr]` inherited attributes
which are used to pass lists of threads and groups which are used in certain
attributes:
* `parName :: String`: The name of the implementation, as before
* `threadType :: Type`: The C type to give threads
* `groupType :: Type`: The C type to give groups
* `initializeThread :: (Expr ::= Expr Exprs Location)`: Initialize a thread,
  the first argument is the left-hand side of the initialization
* `threadDeleteProd :: Maybe<(Stmt ::= Expr)>`: Delete a thread
* `initializeGroup :: (Expr ::= Expr Exprs Location)`: Initialize a group
* `groupDeleteProd :: Maybe<(Stmt ::= Expr)>`: Delete a group
* `threadBefrOps :: Stmt`: Generates the "before" statements of the provided
  threads (via `threads`) which should be executed before a task is created
* `threadThrdOps :: Stmt`: Generates the "thread" statement of the provided
  threads which should be executed before a task commences, but should be done
  by that thread itself (this is currently not used, but is supported in-case
  some implementation wants to make use of the TCB of tasks)
* `threadPostOps :: Stmt`: Generates the "post" statement of the provided
  threads which should be executed once a task completes (but before the task
  exits)
* `groupBefrOps :: Stmt`: Generates the "before" statements of the provided
  groups (via `groups`)
* `groupThrdOps :: Stmt`: Generates the "thread" statements of the provided
  groups
* `groupPostOps :: Stmt`: Generates the "post" statements of the provided
  groups
* `syncThreads :: Stmt`: Generates a statement to synchronize all of the
  provided threads
* `syncGroups :: Stmt`: Generates a statement to synchronize all of the provided
  groups

### Balancer
`BalancerSystem` (defined
[here](grammars/edu.umn.cs.melt.exts.ableC.parallel/abstractsyntax/balancer/BalancerSystem.sv))

* `parName`: The name, as before; currently not used but provided so that all
  system nonterminals have this attribute
* `newProd :: Maybe<(Expr ::= Exprs Location)>`: Implementation of `new`
* `deleteProd :: Maybe<(Stmt ::= Expr)>`: Implementation of `delete`

## Building Higher-Level Abstractions
Implementing higher-level abstractions built on-top of ableC parallel can make
use of the abstract productions provided in ableC parallel, or in some cases it
may be easier to directly make use of the system nonterminals discussed above
and pull attributes from these to generate the appropriate code. In either case
the results should be the same, the choice is really based on the style of the
extension developer.
