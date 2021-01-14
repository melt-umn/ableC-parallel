#include <stdio.h>
#include <ableC_parallel.h>
#include "testing.xh"

int f(int z) {
  return (z << 4) * (z >> 1);
}

int main() {
  testing parallel system;
  
  testing thread th;
  testing group g;

  int x;
  spawn x = f(7); by system;
  spawn x = f(4); by system; in g;
  spawn f(99); by system; as th;
  spawn x += f(7); by system; in g;
  spawn ({printf("Hi!\n"); f(4); }); by system;

  sync th, g;

  sync;

  parallel for (int i = 0; i < 10; i++) by system;
    printf("%d\n", i);

  parallel for (int i = 0; i < 53; i += 2) by system; {
    printf("%d\n", i);
  }

  parallel for (int i = 0; i > -10; i--) by system;
    printf("Hello\n");

  parallel for (int i = 0; i < 100; i += 7) by system; {
    printf("Bad...\n");
  }

  parallel for (int i = 8; i < 12; i += 1) { by system;
    printf("Testing...\n");
  }

  parallel for (int i = 9; i < 35; i += 2) { by system;
    printf("Test: %d\n", f(7));
    printf("Testing... %d\n", f(77));
  }

  parallel for (int i = 77; i < 100; i += 7) { by system;
    printf("%d\n", i);
  }

  parallel for(int i = 100; i >= 0; i -= 2) by system; 
    printf("%d\n", i);
  parallel for(int j = 7; j < 100; j += (2 * 77)) by system;
    printf("%d\n", j);

  parallel for(int i = 0; i < 99; i += 7) by system;
    printf("%d\n", i);
  parallel for(int i = 0; 93 > i; i += 1) by system;
    printf("%d\n", i);

  testing lock lk;
  testing condvar cv;

  acquire &lk;

  wait &cv;
  broadcast &cv;

  release &lk;

  testing lock* ptr = &lk;
  testing condvar* pc = &cv;

  acquire ptr;
  wait pc;
  signal pc;
  release ptr;
}
