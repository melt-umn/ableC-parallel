#ifndef ABLEC_PARALLEL_BLOCKING_
#define ABLEC_PARALLEL_BLOCKING_

#include <ableC_parallel.h>
#include <stdio.h>

struct __attribute__((refId("edu:umn:cs:melt:exts:ableC:parallel:blocking:lock")))
  __blocking_lock {
    __ableC_spinlock spinlock;
    int status;
    struct __ableC_tcb* cur_holding;
    struct __ableC_tcb* waiting_head;
    struct __ableC_tcb* waiting_tail;
};

struct __attribute__((refId("edu:umn:cs:melt:exts:ableC:parallel:blocking:condvar")))
  __blocking_condvar {
    struct __blocking_lock* lk;
    struct __ableC_tcb* waiting_head;
    struct __ableC_tcb* waiting_tail;
};

struct __attribute__((refId("edu:umn:cs:melt:exts:ableC:parallel:blocking:sync")))
  __blocking_sync {
    __ableC_spinlock spinlock;
    int work;
    int waiting;

    // We only maintain one pointer, which basically gives us a stack, because
    // we never need to just wake up one thread (when we want to awaken a
    // thread that has been waiting for a while already), with synchronization
    // we always wake all threads simultaneously, so there's no reason to use
    // a queue.
    struct __ableC_tcb* waiting_head;
};

#endif // ABLEC_PARALLEL_BLOCKING_
