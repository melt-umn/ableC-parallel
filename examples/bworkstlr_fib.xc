#include <ableC_posix.h>
#include <ableC_bworkstlr.h>
#include <ableC_fcfs.h>
#include <stdio.h>
#include <stdlib.h>

bworkstlr parallel thds;
parallel by thds int fib(int n);
parallel by thds int fib(int n) { 
  if (n <= 1) return n;
  else {
    int x, y;
    spawn x = fib(n-1);
    spawn y = fib(n-2);
    sync;
    return x + y;
  }
}

int main(int argc, char** argv) {
  if (argc != 2) {
    fprintf(stderr, "Usage: %s <n>\n", argv[0]);
    exit(-1);
  }
  int n = atoi(argv[1]);

  fcfs balancer blncr = new fcfs balancer(8);
  // NOTE: We initialize with both the balancer and the maximum number of
  // threads that the workstealer can ever have so that we can initialize enough
  // deques ahead of time
  thds = new bworkstlr parallel(blncr, 8);

  posix group grp; grp = new posix group();

  int x;
  spawn x = fib(n); by thds; in grp;

  sync grp;

  printf("fib(%d) = %d\n", n, x);

  delete grp;
  delete thds;
  delete blncr;

  return 0;
}
