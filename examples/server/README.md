# N-Queens Server Example
This file explains the example that is contained within this directory, and
discusses the implementation decisions made.

The idea is that we have a server interface to which you can request the "next"
solution to the N-Queens problem from some initial starting configuration of the
board (for these purposes we associated a configuration on a board of size n, 
which we limit to 64 for convenience, as an n-digit number in base-n and finding 
the "next" solution is the problem of finding the next largest number which
represents a solution to the n-queens problem). You can also request the number
of total solutions for some n.

The server receives requests and these are accepted and parsed by a set of
threads. These threads are simply pthreads since we cannot get any benefit by
using anything more advanced since these threads will block into the OS for
I/O operations. They receive the connection and read the message and then
spawn a processing task into a thread-pool dedicated to processing. To process
a request we determine whether it is asking for the next solution from some
initial state or asking for the number of solutions for some n. If it is the
former, we spawn it into a thread-pool dedicated to these search requests, and
if it is the later we spawn it into a work-stealing system dedicated to count
requests. The reason for this difference is that the counting process can be
extremely parallelized and so a work-stealer is useful, while the search problem
is just looking for a single deterministic result and so parallelism is difficult
and not very effective, so we simply use a single logical thread for each
request. The processing pool is kept separate from the pools used to determine
the results so that we can continue to process requests regardless of what work
is being done on computations. We do this by using `blocking` synchronization,
and once the result is returned, we place the request and result onto a
bounded buffer that is read by a set of writing threads (which, again are just
threads since they may deal with OS blocking related to I/O).

The `tester.out` (produced by the Makefile) can be used to send individual
requests to the server (when it is up and running). Some examples:
```
#6______
>6000000
```
(Note that the \_ should be replaced with spaces).
The server can be shutdown properly by typing "quit" at the command-line.
