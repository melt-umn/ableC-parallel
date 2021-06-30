#ifndef INCLUDE_TIMING_H_
#define INCLUDE_TIMING_H_

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define START_TIMING { \
  struct timespec begin, end; \
  int retBegin, retEnd; \
  retBegin = clock_gettime(CLOCK_MONOTONIC, &begin);

#define STOP_TIMING \
  retEnd = clock_gettime(CLOCK_MONOTONIC, &end); \
  if (retBegin || retEnd) { \
    fprintf(stderr, "Error in clock_gettime\n"); \
    exit(4); \
  } \
  long diff_nsec = end.tv_nsec - begin.tv_nsec; \
  time_t diff_sec = end.tv_sec - begin.tv_sec; \
  if (diff_nsec < 0) { \
    diff_sec -= 1; \
    diff_nsec += 1000000000L; \
  } \
  printf("Elapsed Time: %ld.%09ld\n", diff_sec, diff_nsec); \
}

#endif // INCLUDE_TIMING_H_
