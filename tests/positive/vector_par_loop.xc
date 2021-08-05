#include <ableC_posix.h>
#include <ableC_vector.h>
#include <stdlib.h>

#define N 100
#define N_THREADS 4
#define EXPECTED 338350

int main() {
  vectorize parallel thrds = new vectorize parallel();
  posix parallel pthrds = new posix parallel();
  posix group grp; grp = new posix group();

  int* arr = malloc(sizeof(int) * N);

  for (int i = 0; i < N; i++) {
    arr[i] = i + 1;
  }

  parallel for (int i = 0; i < N; i++)
    by thrds; par-by pthrds; num-threads N_THREADS; private arr; in grp;
  {
    arr[i] *= arr[i];
  }
  sync grp;

  int check = 0;
  for (int i = 0; i < N; i++) {
    check += arr[i];
  }
  if (check != EXPECTED) {
    exit(1);
  }

  free(arr);
  delete grp;
  delete pthrds;
  delete thrds;

  return 0;
}
