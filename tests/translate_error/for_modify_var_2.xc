#include <stdio.h>

int main() {
  parallel for (int i = 0; i < 100; i++) {
    printf("%d\n", i);
    int* p = &i;
    *p += 1;
  }
  return 0;
}
