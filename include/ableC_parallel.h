#ifndef INCLUDE_ABLEC_PARALLEL_
#define INCLUDE_ABLEC_PARALLEL_

#include <stdlib.h>
#include <pthread.h>

enum __ableC_thread_status {
    UNUSED, READY, RUNNING, BLOCKING, BLOCKED, UNBLOCKING
};

__attribute__((refId("edu:umn:cs:melt:exts:ableC:parallel:thread-info"))) 
  struct __ableC_tcb;

struct __attribute__((refId("edu:umn:cs:melt:exts:ableC:parallel:system-info")))
  __ableC_system_info {
    int system_id;
    int system_spec_id; // can be used to number different instances if needed by the system
    void* system_data;
    void (*block)(struct __ableC_tcb*);
    void (*unblock)(struct __ableC_tcb*);
};

struct __attribute__((refId("edu:umn:cs:melt:exts:ableC:parallel:thread-info")))
  __ableC_tcb {
    struct __ableC_system_info* system;
    void* thread_info;
    struct __ableC_tcb* parent;
    enum __ableC_thread_status status;
};

_Thread_local struct __ableC_tcb* __ableC_thread_tcb;

struct __ableC_main_thread_info {
  pthread_mutex_t lk;
  pthread_cond_t  cv;
};

void __ableC_main_thread_block(struct __ableC_tcb* tcb) {
  struct __ableC_main_thread_info* info = 
    (struct __ableC_main_thread_info*) (tcb->thread_info);

  pthread_mutex_lock(&(info->lk));
  while (tcb->status != UNBLOCKING) {
    tcb->status = BLOCKING;
    pthread_cond_wait(&(info->cv), &(info->lk));
  }
  tcb->status = RUNNING;
  pthread_mutex_unlock(&(info->lk));
}

void __ableC_main_thread_unblock(struct __ableC_tcb* tcb) {
  struct __ableC_main_thread_info* info = 
    (struct __ableC_main_thread_info*) (tcb->thread_info);

  pthread_mutex_lock(&(info->lk));
  if (tcb->status == BLOCKING) {
    pthread_cond_signal(&(info->cv));
  }
  
  tcb->status = UNBLOCKING;
  pthread_mutex_unlock(&(info->lk));
}

struct __ableC_system_info __ableC_main_thread = 
  {0, 0, NULL, __ableC_main_thread_block, __ableC_main_thread_unblock};
struct __ableC_main_thread_info __ableC_main_info = 
  {PTHREAD_MUTEX_INITIALIZER, PTHREAD_COND_INITIALIZER};
struct __ableC_tcb __ableC_main_tcb = 
  {&__ableC_main_thread, &__ableC_main_info, NULL, RUNNING};

void __attribute__((constructor)) __ableC_init_main_thread_tcb() {
  __ableC_thread_tcb = &__ableC_main_tcb;
}

#endif // INCLUDE_ABLEC_PARALLEL_
