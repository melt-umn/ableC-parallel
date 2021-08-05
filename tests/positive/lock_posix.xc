#include <ableC_posix.h>
#include <stdlib.h>

#define N 10000

posix lock lck;
int val = 0;

void func() {
  for (int i = 0; i < N; i++) {
    acquire lck;
    val++;
    release lck;
  }
}

int main() {
  posix parallel thrds = new posix parallel();
  posix group grp; grp = new posix group();
  lck = new posix lock();

  spawn func(); by thrds; in grp; global func;
  spawn func(); by thrds; in grp; global func;
  sync grp;

  if (val != 2 * N) {
    exit(1);
  }

  delete lck;
  delete grp;
  delete thrds;
  
  return 0;
}
