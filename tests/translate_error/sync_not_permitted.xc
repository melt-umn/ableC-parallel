#include <ableC_posix.h>

typedef posix synchronized <int> = {
  condition zero(this == 0);

  when (this) += 1 then broadcast not zero;
  when (this) = 0 then broadcast zero;
} sInt;

int main() {
  sInt val; val = new sInt(0);

  holding (val) as v {
    v--;
  }
}
