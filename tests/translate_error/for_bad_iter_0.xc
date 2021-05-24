#include <stdio.h>
#include <ableC_parallel.h>
#include <ableC_posix.h>

int main() {
  int j;

  posix parallel system;
  
  parallel for (int i = 0; i < 10; j++) { by system;
    printf("%d\n", i);
  }
}
