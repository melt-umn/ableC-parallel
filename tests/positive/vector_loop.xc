#include <ableC_vector.h>
#include <stdlib.h>

#define N 100
#define EXPECTED 338350

int main() {
  vectorize parallel thrds = new vectorize parallel();

  int* arr = malloc(sizeof(int) * N);

  for (int i = 0; i < N; i++) {
    arr[i] = i + 1;
  }

  parallel for (int i = 0; i < N; i++)
    by thrds;
  {
    arr[i] *= arr[i];
  }

  int check = 0;
  for (int i = 0; i < N; i++) {
    check += arr[i];
  }
  if (check != EXPECTED) {
    exit(1);
  }

  free(arr);
  delete thrds;

  return 0;
}
