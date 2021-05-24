#include <stdio.h>
#include <ableC_parallel.h>

int main() {
  parallel for (int i = 0; i < 77; i++) {
    printf("%d\n", i);
  }

  return 0;
}
