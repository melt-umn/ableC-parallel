#ifndef ABLEC_BTHRDPOOL_H_
#define ABLEC_BTHRDPOOL_H_

#include <ableC_thrdpool.h>
#include <ableC_balancer.h>

struct __attribute__((refId("edu:umn:cs:melt:exts:ableC:parallel:exts:balancer:uses:bthrdpool:system")))
  __bthrdpool_system_info {
  volatile _Atomic int num_thrds; // Need to keep the same as thrdpool version
  pthread_mutex_t lk;
  pthread_cond_t cv;
  struct __thrdpool_work_item* work_head;
  struct __thrdpool_work_item* work_tail;
  pthread_t* threads; // Need for thrdpool version
  int shutdown;
  struct __balancer* bal;
};

extern void* __bthrdpool_launcher(void* inpt);

#endif // ABLEC_BTHRDPOOL_H_
