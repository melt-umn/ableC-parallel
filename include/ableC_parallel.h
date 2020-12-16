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
    enum __ableC_thread_status status;
    struct __ableC_system_info* system;
    void* thread_info;
    struct __ableC_tcb* parent;
    struct __ableC_tcb* next; // next pointer to make lists of TCBs easier
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
  {RUNNING, &__ableC_main_thread, &__ableC_main_info, NULL, NULL};

void __attribute__((constructor)) __ableC_init_main_thread_tcb() {
  __ableC_thread_tcb = &__ableC_main_tcb;
}

// Spinlocks
typedef volatile _Atomic int __ableC_spinlock;

void inline __ableC_spinlock_acquire(__ableC_spinlock* lk) {
  // Personally, I'm not a huge fan of this implementation (which is the one used
  // by glibc for pthread's) because at some point we theoretically can get
  // overflow of the int back to negative and then 0. However, I agree it is
  // probably sufficiently unlikely (it would require 2^32 ~ 4 Billion increments)
  // On my Laptop a single thread requires ~24 s to wrap from 1 back to 0,
  // two threads takes ~60 s (increase presumably due to cache contention),
  // and three or more threads takes over 80 s. This suggests that as long as
  // spinlocks are always held very temporarily this problem shouldn't manifest
  while ((*lk)++ != 0) ;
}

void inline __ableC_spinlock_release(__ableC_spinlock* lk) {
  (*lk) = 0;
}

#endif // INCLUDE_ABLEC_PARALLEL_
