#include <stdio.h>

int main() {
  parallel for (int i = 0; i < 100; i++) {
    printf("%d\n", i);
    i *= 2;
  }
  return 0;
}
