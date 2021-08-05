#include <ableC_bworkstlr.h>
#include <ableC_fcfs.h>
#include <ableC_posix.h>
#include <stdlib.h>

#define N 100
#define N_CORES 4
#define EXPECTED 338350

bworkstlr parallel thrds;

parallel by thrds int fib(int n);
parallel by thrds int fib(int n) {
  if (n <= 1) return n;

  int x, y;
  spawn x = fib(n-1);
  spawn y = fib(n-2);
  sync;

  return x + y;
}

int main() {
  fcfs balancer bal = new fcfs balancer(N_CORES);
  thrds = new bworkstlr parallel(bal, N_CORES);
  posix group grp; grp = new posix group();

  int v1, v2, v3;
  spawn v1 = fib(5); by thrds; in grp;
  spawn v2 = fib(7); by thrds; in grp;
  spawn v3 = fib(9); by thrds; in grp;

  sync grp;
  
  if (v1 != 5 || v2 != 13 || v3 != 34) {
    exit(1);
  }
  
  delete grp;
  delete thrds;

  return 0;
}
