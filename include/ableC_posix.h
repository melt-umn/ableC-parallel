#ifndef ABLEC_POSIX_H_
#define ABLEC_POSIX_H_

#include <ableC_parallel.h>

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

struct __attribute__((refId("edu:umn:cs:melt:exts:ableC:parallel:impl:posix:mutex")))
  __posix_mutex {
    pthread_mutex_t lk;
    struct __ableC_tcb* cur_holding;
};

struct __attribute__((refId("edu:umn:cs:melt:exts:ableC:parallel:impl:posix:condvar")))
  __posix_condvar {
  pthread_cond_t cv;
  struct __posix_mutex* lk;
};

struct __attribute__((refId("edu:umn:cs:melt:exts:ableC:parallel:impl:posix:sync")))
  __posix_sync {
  pthread_mutex_t lk;
  pthread_cond_t cv;
  int work;
  int waiting;
};

struct __attribute__((refId("edu:umn:cs:melt:exts:ableC:parallel:impl:posix:thread")))
  __posix_thread_info {
  pthread_mutex_t lk;
  pthread_cond_t cv;
};

static void __posix_block_func(struct __ableC_tcb* tcb) {
  struct __posix_thread_info* info = (struct __posix_thread_info*) tcb->thread_info;

  checked_pthread_mutex_lock(&(info->lk));
  while (tcb->status != UNBLOCKING) {
    tcb->status = BLOCKING;
    checked_pthread_cond_wait(&(info->cv), &(info->lk));
  }
  tcb->status = RUNNING;
  checked_pthread_mutex_unlock(&(info->lk));
}

static void __posix_unblock_func(struct __ableC_tcb* tcb) {
  struct __posix_thread_info* info = (struct __posix_thread_info*) tcb->thread_info;

  checked_pthread_mutex_lock(&(info->lk));
  
  checked_pthread_cond_signal(&(info->cv));
  tcb->status = UNBLOCKING;
  
  checked_pthread_mutex_unlock(&(info->lk));
}

#endif  // ABLEC_POSIX_H_
