#ifndef ABLEC_THRDPOOL_H_
#define ABLEC_THRDPOOL_H_

#include <ableC_parallel.h>
#include <pthread.h>
#include <setjmp.h>

struct __attribute__((refId("edu:umn:cs:melt:exts:ableC:parallel:impl:thrdpool:work")))
  __thrdpool_work_item {
  int started; // 0 for a new work item, 1 for an item to be resumed, -1 means exit
  __ableC_spinlock spinlock;

  struct __thrdpool_work_item* next;
  union {
    struct {
      void (*f)(void*);
      void* args;
      struct __ableC_tcb* parent;
    } start;
    struct {
      void* stack;
      struct __ableC_tcb tcb;
      jmp_buf env;
    } resume;
  } contents;
};

struct __attribute__((refId("edu:umn:cs:melt:exts:ableC:parallel:impl:thrdpool:system")))
  __thrdpool_system_info {
  _Atomic int num_thrds;
  pthread_mutex_t lk;
  pthread_cond_t cv;
  struct __thrdpool_work_item* work_head;
  struct __thrdpool_work_item* work_tail;
  pthread_t* threads;
};

extern _Thread_local jmp_buf __thrdpool_return;
extern _Thread_local void* __thrdpool_please_free;

extern void* __thrdpool_launcher(void* inpt);
extern void __thrdpool_block_func(struct __ableC_tcb* tcb);
extern void __thrdpool_unblock_func(struct __ableC_tcb* tcb);

#endif  // ABLEC_THRDPOOL_H_
