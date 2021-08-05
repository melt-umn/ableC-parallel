#include <ableC_thrdpool.h>
#include <stdlib.h>

#define N_CORES 3

void forever() {
  while (1) ;
}

int main() {
  thrdpool parallel thrds = new thrdpool parallel(N_CORES);

  spawn forever(); by thrds; global forever;
  
  delete thrds;

  return 0;
}
