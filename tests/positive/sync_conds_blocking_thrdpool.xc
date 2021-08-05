#include <ableC_blocking.h>
#include <ableC_thrdpool.h>
#include <stdlib.h>

#define N 10000

typedef blocking synchronized<int> = {
  condition zero(this == 0);

  when (this) += 1 then broadcast not zero;
  when (this) =  0 then broadcast zero;
} sInt;
sInt val;

void f() {
  for (int i = 0; i < N; i++) {
    holding (val) as v {
      SN::wait until v.zero;
      v++;
    }
  }
}

void g() {
  for (int i = 0; i < N; i++) {
    holding (val) as v {
      SN::wait while v.zero;
      v = 0;
    }
  }
}

int main() {
  val = new sInt(0);

  thrdpool parallel thrds = new thrdpool parallel(2);
  blocking group grp; grp = new blocking group();

  spawn f(); by thrds; in grp; global f;
  spawn g(); by thrds; in grp; global g;
  sync grp;

  delete val;
  delete grp;
  delete thrds;
  
  return 0;
}
