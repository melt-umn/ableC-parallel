#ifndef INCLUDE_ABLEC_PARALLEL_
#define INCLUDE_ABLEC_PARALLEL_

#include <stdlib.h>

struct __attribute__((refId("edu:umn:cs:melt:exts:ableC:parallel:system-info")))
  __ableC_system_info {
    int system_id;
    int system_spec_id; // can be used to number different instances if needed by the system
    void* system_data;
};

struct __attribute__((refId("edu:umn:cs:melt:exts:ableC:parallel:thread-info")))
  __ableC_tcb {
    struct __ableC_system_info* system;
    void* thread_info;
    struct __ableC_tcb* parent;
};

_Thread_local struct __ableC_tcb* __ableC_thread_tcb;

struct __ableC_system_info __ableC_main_thread = {0, 0, NULL};
struct __ableC_tcb __ableC_main_tcb = {&__ableC_main_thread, NULL, NULL};

void __attribute__((constructor)) __ableC_init_main_thread_tcb() {
  __ableC_thread_tcb = &__ableC_main_tcb;
}

#endif // INCLUDE_ABLEC_PARALLEL_
