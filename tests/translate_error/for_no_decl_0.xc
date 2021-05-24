#include <stdio.h>
#include <ableC_parallel.h>
#include <ableC_posix.h>

int main() {
  int i = 0;

  posix parallel system;
  parallel for (i = 0; i < 10; i++) { by system;
    printf("%d\n", i);
  }
}
