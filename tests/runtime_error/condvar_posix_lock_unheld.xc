#include <ableC_posix.h>
#include <stdlib.h>

int main() {
  posix lock lck; lck = new posix lock();
  posix condvar cv; cv = new posix condvar(&lck);

  signal cv;

  return 0;
}
