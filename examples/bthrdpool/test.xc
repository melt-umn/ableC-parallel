#include <ableC_posix.h>
#include <ableC_bthrdpool.h>
#include <ableC_fcfs.h>
#include <stdio.h>
#include <stdlib.h>
#include "timing.h"

#define ARRAY_LEN 10000000
#define RANDOM 0.5
#define MIN_COST 10
#define MAX_COST 1000
#define REPEATS 10

double operator(double val) {
  double x = 1;
  int iters = MIN_COST + (int) (val * (MAX_COST - MIN_COST));
  for (int i = 0; i < iters; i++) {
    x += i * x;
  }
  return x;
}

int main() {
  srand(314159);

  double* arr1 = malloc(sizeof(double) * ARRAY_LEN);
  double* arr2 = malloc(sizeof(double) * ARRAY_LEN);

  for (int i = 0; i < ARRAY_LEN; i++) {
    arr1[i] = (1 - RANDOM) * ((1.0 / (ARRAY_LEN - 1)) * i)
            +      RANDOM  * (((double) rand()) / RAND_MAX);
    arr2[i] = (1 - RANDOM) * ((1.0 / (ARRAY_LEN - 1)) * i)
            +      RANDOM  * (((double) rand()) / RAND_MAX);
  }
  
  fcfs balancer blncr = new fcfs balancer(8);
  bthrdpool parallel p1 = new bthrdpool parallel(blncr);
  bthrdpool parallel p2 = new bthrdpool parallel(blncr);

  posix group grp; grp = new posix group();

  START_TIMING
  for (int i = 0; i < REPEATS; i++) {
    parallel for (int i = 0; i < ARRAY_LEN; i++)
      by p1; in grp; private arr1; global operator; num-threads 32;
    {
      operator(arr1[i]);
    }
    
    parallel for (int i = 0; i < ARRAY_LEN; i++)
      by p2; in grp; private arr2; global operator; num-threads 32;
    {
      operator(arr2[i]);
    }
    
    sync grp;
  }
  STOP_TIMING

  free(arr1); free(arr2);

  delete p1; delete p2;
  delete grp; delete blncr;

  return 0;
}
