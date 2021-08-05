#include <ableC_blocking.h>
#include <ableC_thrdpool.h>
#include <stdlib.h>

#define N 10000

blocking lock lck;
int val = 0;

void func() {
  for (int i = 0; i < N; i++) {
    acquire lck;
    val++;
    release lck;
  }
}

int main() {
  thrdpool parallel thrds = new thrdpool parallel(2);
  blocking group grp; grp = new blocking group();
  lck = new blocking lock();

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
