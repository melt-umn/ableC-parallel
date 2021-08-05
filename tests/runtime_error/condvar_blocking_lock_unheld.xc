#include <ableC_blocking.h>
#include <stdlib.h>

int main() {
  blocking lock lck; lck = new blocking lock();
  blocking condvar cv; cv = new blocking condvar(&lck);

  signal cv;

  return 0;
}
