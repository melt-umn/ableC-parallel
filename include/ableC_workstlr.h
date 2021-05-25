#ifndef INCLUDE_ABLEC_WORKSTLR_H_
#define INCLUDE_ABLEC_WORKSTLR_H_

#include <stdio.h>
#include <setjmp.h>

#include <ableC_workstlr_alloc.h>
#include <ableC_workstlr_deque.h>

#include <ableC_parallel.h>

extern _Thread_local struct workstlr_deque* workstlr_thread_deque;
extern _Thread_local jmp_buf workstlr_jmp_buf;

struct workstlr_system {
  int nThreads;
  volatile int shutdown;
  pthread_barrier_t barrier;
  struct workstlr_deque* deques;
  pthread_t* threads;
};

// In practice we always use some other struct that has the function in this
// as its first member and has other things after that
struct workstlr_closure {
  void (*func)(void*);
  _Atomic int joinCounter;
};

struct __ableC_system_info* start_workstlr_system(int, int);
void stop_workstlr_system(struct __ableC_system_info*);

#endif
