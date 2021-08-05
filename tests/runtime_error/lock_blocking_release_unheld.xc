#include <ableC_blocking.h>
#include <stdlib.h>

int main() {
  blocking lock lck; lck = new blocking lock();

  release lck;

  return 0;
}
