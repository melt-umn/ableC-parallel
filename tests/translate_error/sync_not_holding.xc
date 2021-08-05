#include <ableC_posix.h>

typedef posix synchronized <int> sInt;

int main() {
  sInt val; val = new sInt(0);

  val += 1;
}
