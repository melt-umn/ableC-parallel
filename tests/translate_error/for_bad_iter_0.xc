#include <stdio.h>
#include <ableC_parallel.h>

#include "testing.xh"

int main() {
  int j;

  testing parallel system;
  
  parallel for (int i = 0; i < 10; j++) { by system;
    printf("%d\n", i);
  }
}
