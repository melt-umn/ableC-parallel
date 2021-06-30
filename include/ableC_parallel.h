#ifndef INCLUDE_ABLEC_PARALLEL_
#define INCLUDE_ABLEC_PARALLEL_

#include <stdio.h>
#include <string.h>
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

  int errnum;
  errnum = pthread_attr_init(&attr);
  if (errnum) {
    fprintf(stderr, "Error in pthread_attr_init during setup: %s\n", strerror(errnum));
    exit(-1);
  }

  errnum = pthread_attr_getstacksize(&attr, &__ableC_stack_size);
  if (errnum) {
    fprintf(stderr, "Error in pthread_attr_getstacksize during setup: %s\n", strerror(errnum));
    exit(-1);
  }

  errnum = pthread_attr_destroy(&attr);
  if (errnum) {
    fprintf(stderr, "Error in pthread_attr_destroy during setup: %s\n", strerror(errnum));
    exit(-1);
  }
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

// Functions for using pthread mutex/condvars with appropriate error checking
static void inline checked_pthread_mutex_lock(pthread_mutex_t* lk) {
  int errnum = pthread_mutex_lock(lk);
  if (__builtin_expect(errnum, 0)) {
    fprintf(stderr, "Error in pthread_mutex_lock: %s\n", strerror(errnum));
    exit(-1);
  }
}
static void inline checked_pthread_mutex_unlock(pthread_mutex_t* lk) {
  int errnum = pthread_mutex_unlock(lk);
  if (__builtin_expect(errnum, 0)) {
    fprintf(stderr, "Error in pthread_mutex_unlock: %s\n", strerror(errnum));
    exit(-1);
  }
}
static void inline checked_pthread_cond_wait(pthread_cond_t* cv, pthread_mutex_t* lk) {
  int errnum = pthread_cond_wait(cv, lk);
  if (__builtin_expect(errnum, 0)) {
    fprintf(stderr, "Error in pthread_cond_wait: %s\n", strerror(errnum));
    exit(-1);
  }
}
static void inline checked_pthread_cond_signal(pthread_cond_t* cv) {
  int errnum = pthread_cond_signal(cv);
  if (__builtin_expect(errnum, 0)) {
    fprintf(stderr, "Error in pthread_cond_signal: %s\n", strerror(errnum));
    exit(-1);
  }
}
static void inline checked_pthread_cond_broadcast(pthread_cond_t* cv) {
  int errnum = pthread_cond_broadcast(cv);
  if (__builtin_expect(errnum, 0)) {
    fprintf(stderr, "Error in pthread_cond_broadcast: %s\n", strerror(errnum));
    exit(-1);
  }
}
static void inline checked_pthread_mutex_init(pthread_mutex_t* lk, const pthread_mutexattr_t *restrict attr) {
  int errnum = pthread_mutex_init(lk, attr);
  if (__builtin_expect(errnum, 0)) {
    fprintf(stderr, "Error in pthread_mutex_init: %s\n", strerror(errnum));
    exit(-1);
  }
}
static void inline checked_pthread_mutex_destroy(pthread_mutex_t* lk) {
  int errnum = pthread_mutex_destroy(lk);
  if (__builtin_expect(errnum, 0)) {
    fprintf(stderr, "Error in pthread_mutex_destroy: %s\n", strerror(errnum));
    exit(-1);
  }
}
static void inline checked_pthread_cond_init(pthread_cond_t* cv, const pthread_condattr_t *restrict attr) {
  int errnum = pthread_cond_init(cv, attr);
  if (__builtin_expect(errnum, 0)) {
    fprintf(stderr, "Error in pthread_cond_init: %s\n", strerror(errnum));
    exit(-1);
  }
}
static void inline checked_pthread_cond_destroy(pthread_cond_t* cv) {
  int errnum = pthread_cond_destroy(cv);
  if (__builtin_expect(errnum, 0)) {
    fprintf(stderr, "Error in pthread_cond_destroy: %s\n", strerror(errnum));
    exit(-1);
  }
}
static void inline checked_pthread_create(pthread_t* restrict thread,
                      const pthread_attr_t* restrict attr,
                      void* (*start_routine)(void*), void* restrict arg) {
  int errnum = pthread_create(thread, attr, start_routine, arg);
  if (__builtin_expect(errnum, 0)) {
    fprintf(stderr, "Error in pthread_create: %s\n", strerror(errnum));
    exit(-1);
  }
}

static void inline checked_pthread_attr_init(pthread_attr_t* attr) {
  int errnum = pthread_attr_init(attr);
  if (__builtin_expect(errnum, 0)) {
    fprintf(stderr, "Error in pthread_attr_init: %s\n", strerror(errnum));
    exit(-1);
  }
}
static void inline checked_pthread_attr_destroy(pthread_attr_t* attr) {
  int errnum = pthread_attr_destroy(attr);
  if (__builtin_expect(errnum, 0)) {
    fprintf(stderr, "Error in pthread_attr_destroy: %s\n", strerror(errnum));
    exit(-1);
  }
}
static void inline checked_pthread_attr_setdetachstate(pthread_attr_t* attr,
                                                            int detachstate) {
  int errnum = pthread_attr_setdetachstate(attr, detachstate);
  if (__builtin_expect(errnum, 0)) {
    fprintf(stderr, "Error in pthread_attr_setdetachstate: %s\n", strerror(errnum));
    exit(-1);
  }
}

#endif // INCLUDE_ABLEC_PARALLEL_
