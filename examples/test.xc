#include <stdio.h>

int f(int z) {
  return (z << 4) * (z >> 1);
}

int main() {
  int x;
  spawn x = f(4);
  spawn f(99);
  spawn x += f(7);
  spawn ({printf("Hi!\n"); f(4); });

  sync;

  parallel for (int i = 0; i < 10; i++)
    printf("%d\n", i);

  parallel for (int i = 0; i < 53; i += 2) {
    printf("%d\n", i);
  }

  parallel for (int i = 0; i > -10; i--) as nothing
    printf("Hello\n");

  parallel for (int i = 0; i < 100; i += 7) as nothing {
    printf("Bad...\n");
  }

  parallel for (int i = 8; i < 12; i += 1) { by something
    printf("Testing...\n");
  }

  parallel for (int i = 9; i < 35; i += 2) { in what
    printf("Test: %d\n", f(7));
    printf("Testing... %d\n", f(77));
  }
}
