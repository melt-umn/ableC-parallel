#include <ableC_posix.h>
#include <stdlib.h>

int main() {
  posix lock lck; lck = new posix lock();

  release lck;

  return 0;
}
