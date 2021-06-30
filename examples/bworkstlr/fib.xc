#include <ableC_posix.h>
#include <ableC_bworkstlr.h>
#include <ableC_fcfs.h>
#include <stdio.h>
#include <stdlib.h>

workstlr_func int fib(int n) { 
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
  bworkstlr parallel thds = new bworkstlr parallel(blncr, 8);

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
