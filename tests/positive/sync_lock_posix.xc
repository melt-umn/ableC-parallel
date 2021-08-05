#include <ableC_posix.h>
#include <stdlib.h>

#define N 10000

typedef posix synchronized<int> sInt;
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
  posix group grp; grp = new posix group();

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
