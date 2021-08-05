#include <ableC_blocking.h>
#include <ableC_thrdpool.h>
#include <stdlib.h>

#define N 10000

blocking lock lck;
blocking condvar cv;
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
  thrdpool parallel thrds = new thrdpool parallel(2);
  blocking group grp; grp = new blocking group();
  lck = new blocking lock();
  cv = new blocking condvar(&lck);

  spawn f(); by thrds; in grp; global f;
  spawn g(); by thrds; in grp; global g;
  sync grp;

  delete cv;
  delete lck;
  delete grp;
  delete thrds;
  
  return 0;
}
