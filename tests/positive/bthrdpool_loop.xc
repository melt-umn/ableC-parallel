#include <ableC_bthrdpool.h>
#include <ableC_blocking.h>
#include <ableC_fcfs.h>
#include <stdlib.h>

#define N 100
#define N_THREADS 4
#define N_CORES 3
#define EXPECTED 338350

int main() {
  fcfs balancer bal = new fcfs balancer(N_CORES);
  bthrdpool parallel thrds = new bthrdpool parallel(bal);
  blocking group grp; grp = new blocking group();

  int* arr = malloc(sizeof(int) * N);

  for (int i = 0; i < N; i++) {
    arr[i] = i + 1;
  }

  parallel for (int i = 0; i < N; i++)
    by thrds; in grp; num-threads N_THREADS; private arr;
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
  delete thrds;
  delete bal;

  return 0;
}
