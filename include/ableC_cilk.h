#ifndef INCLUDE_ABLEC_CILK_H_
#define INCLUDE_ABLEC_CILK_H_

#include <stdio.h>
#include <setjmp.h>

#include <ableC_cilk_alloc.h>
#include <ableC_cilk_deque.h>

#include <ableC_parallel.h>

extern _Thread_local struct cilk_deque* cilk_thread_deque;
extern _Thread_local jmp_buf cilk_jmp_buf;

struct cilk_system {
  int nThreads;
  volatile int shutdown;
  pthread_barrier_t barrier;
  struct cilk_deque* deques;
  pthread_t* threads;
};

// In practice we always use some other struct that has the function in this
// as its first member and has other things after that
struct cilk_closure {
  void (*func)(void*);
  _Atomic int joinCounter;
};

struct __ableC_system_info* start_cilk_system(int, int);
void stop_cilk_system(struct __ableC_system_info*);

#endif
