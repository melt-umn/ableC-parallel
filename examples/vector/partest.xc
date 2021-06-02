#include <ableC_vector.h>
#include <ableC_posix.h>
#include <stdio.h>
#include <stdlib.h>

#define aligned_malloc(alignment, size) ({ void* res = NULL; posix_memalign(&res, alignment, size); res; })

int main() {
  vectorize parallel vect = new vectorize parallel();
  posix parallel threads = new posix parallel();

  posix group grp; grp = new posix group();

  // Need 32 byte alignment for AVX moves
  double* arr1 = aligned_malloc(32, sizeof(double) * 10);
  double* arr2 = aligned_malloc(32, sizeof(double) * 10);

  unsigned int seed = 31415;

  for (int i = 0; i < 10; i++) {
    arr1[i] = rand_r(&seed);
    arr2[i] = rand_r(&seed);
  }
  
  parallel for (int i = 0; i < 10; i++) by vect; par-by threads; num-threads 4; in grp;
  {
    arr1[i] *= arr1[i] + arr2[i];
  }
  sync grp;

  for (int i = 0; i < 10; i++) {
    printf("%lf\n", arr1[i]);
  }

  free(arr1);
  free(arr2);

  delete vect;

  return 0;
}
