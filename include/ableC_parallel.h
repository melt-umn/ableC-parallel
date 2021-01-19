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

extern _Thread_local struct __ableC_tcb* __ableC_thread_tcb;

struct __ableC_main_thread_info {
  pthread_mutex_t lk;
  pthread_cond_t  cv;
};

extern void __ableC_main_thread_block(struct __ableC_tcb* tcb);
extern void __ableC_main_thread_unblock(struct __ableC_tcb* tcb);

extern struct __ableC_system_info __ableC_main_thread;
extern struct __ableC_main_thread_info __ableC_main_info;
extern struct __ableC_tcb __ableC_main_tcb;

// Constructors don't work if placed in the library (I'm guessing it has to
// be defined in the same object file that contains the definition of main)
#ifndef ABLEC_NON_MAIN
void __attribute__((constructor)) __ableC_init_main_thread_tcb() {
  __ableC_thread_tcb = &__ableC_main_tcb;
}
#endif

extern size_t __ableC_stack_size;
#ifndef ABLEC_NON_MAIN
void __attribute__((constructor)) __ableC_init_stack_size() {
  pthread_attr_t attr;
  pthread_attr_init(&attr);
  pthread_attr_getstacksize(&attr, &__ableC_stack_size);
  pthread_attr_destroy(&attr);
}
#endif

// Spinlocks (the definitions here are intended to be inlined, which is why
// the definition is provided in this header file, rather than the library)
typedef volatile _Atomic int __ableC_spinlock;

static void inline __ableC_spinlock_acquire(__ableC_spinlock* lk) {
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

static void inline __ableC_spinlock_release(__ableC_spinlock* lk) {
  (*lk) = 0;
}

#endif // INCLUDE_ABLEC_PARALLEL_
