#ifndef INCLUDE_ABLEC_BWORKSTLR_H_
#define INCLUDE_ABLEC_BWORKSTLR_H_

#include <stdio.h>
#include <setjmp.h>

#include <ableC_bworkstlr_deque.h>
#include <ableC_workstlr.h>

#include <ableC_balancer.h>
#include <ableC_parallel.h>

// This struct has the same layout as a workstlr_system
struct bworkstlr_system {
  int maxThreads;
  volatile int shutdown;
  pthread_barrier_t barrier; // UNUSED
  struct bworkstlr_deque* deques;
  struct __balancer* bal;     // REPLACED threads (of type pthread_t*)
  
  volatile _Atomic int numThreads;
};

struct __ableC_system_info* start_bworkstlr_system(struct __balancer*, int, int);
void stop_bworkstlr_system(struct __ableC_system_info*);

#endif
