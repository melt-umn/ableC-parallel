#include <ableC_cilk.h>
#include <ableC_posix.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

cilk parallel sys;

parallel by sys int fib(int);

int main(int argc, char** argv) {

  if (argc != 2) {
    fprintf(stderr, "Usage: %s <n>\n", argv[0]);
    exit(-1);
  }

  int n = atoi(argv[1]);
  if (n <= 0) {
    fprintf(stderr, "n must be a positive integer\n");
    exit(-1);
  }

  sys = new cilk parallel(4);
  posix thread thd; thd = new posix thread();

  int res;
  
  struct timespec begin, end;
  int retBegin, retEnd;
  retBegin = clock_gettime(CLOCK_MONOTONIC, &begin);
  
  spawn res = fib(n); by sys; as thd;
  sync thd;

  retEnd = clock_gettime(CLOCK_MONOTONIC, &end);

  if (retBegin || retEnd) {
    fprintf(stderr, "Error in clock_gettime\n");
    exit(3);
  }

  long diff_nsec = end.tv_nsec - begin.tv_nsec;
  time_t diff_sec = end.tv_sec - begin.tv_sec;
  if (diff_nsec < 0) {
    diff_sec -= 1;
    diff_nsec += 1000000000L;
  }

  printf("Elapsed Time: %ld.%09ld\n", diff_sec, diff_nsec);
  printf("fib(%d) = %d\n", n, res);

  delete thd;
  delete sys;

  return 0;
}

parallel by sys int fib(int n) {
  if (n <= 1) return n;

  int x, y;
  spawn x = fib(n-1);
  spawn y = fib(n-2);
  sync;

  return x + y;
}
