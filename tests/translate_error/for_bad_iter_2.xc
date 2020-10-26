#include <stdio.h>

int main() {
  parallel for (int i = 0; i < 10; i += 1 + i) {
    printf("%d\n", i);
  }
}
