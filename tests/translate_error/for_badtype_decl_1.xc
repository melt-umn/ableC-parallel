#include <stdio.h>

int main() {
  parallel for (double i = 0; i < 10; i++) {
    printf("%lf\n", i);
  }
}
