#include <ableC_posix.h>
#include <stdlib.h>

#define N 10000

posix lock lck;
posix condvar cv;
int val = 0;

void f() {
  acquire lck;
  
  while (val < N) {
    while (val % 2 != 0) {
      wait cv;
    }
    val += 1;
    signal cv;
  }
  
  release lck;
}

void g() {
  acquire lck;

  while (val < N) {
    while (val % 2 == 0) {
      wait cv;
    }
    val += 1;
    signal cv;
  }

  release lck;
}

int main() {
  posix parallel thrds = new posix parallel();
  posix group grp; grp = new posix group();
  lck = new posix lock();
  cv = new posix condvar(&lck);

  spawn f(); by thrds; in grp; global f;
  spawn g(); by thrds; in grp; global g;
  sync grp;

  delete cv;
  delete lck;
  delete grp;
  delete thrds;
  
  return 0;
}
