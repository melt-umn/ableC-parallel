#include <stdio.h>

int main() {
  parallel for (int i = 0; i < 10; i = 4) {
    printf("%d\n", i);
  }
}
