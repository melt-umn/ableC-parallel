#define ABLEC_NON_MAIN

#include <stdlib.h>
#include <pthread.h>
#include <ableC_parallel.h>

_Thread_local struct __ableC_tcb* __ableC_thread_tcb;

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

size_t __ableC_stack_size;
