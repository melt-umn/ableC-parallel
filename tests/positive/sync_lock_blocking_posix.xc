#include <ableC_blocking.h>
#include <ableC_thrdpool.h>
#include <ableC_posix.h>
#include <stdlib.h>

#define N 10000

typedef blocking synchronized<int> sInt;
sInt val;

void func() {
  for (int i = 0; i < N; i++) {
    holding (val) as v {
      v++;
    }
  }
}

int main() {
  val = new sInt(0);

  posix parallel thrds = new posix parallel();
  blocking group grp; grp = new blocking group();

  spawn func(); by thrds; in grp; global func;
  spawn func(); by thrds; in grp; global func;
  sync grp;

  holding (val) as v {
    if (v != 2 * N) {
      exit(1);
    }
  }

  delete val;
  delete grp;
  delete thrds;
  
  return 0;
}
