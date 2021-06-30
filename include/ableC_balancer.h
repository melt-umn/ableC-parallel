#ifndef ABLEC_BALANCER_H_
#define ABLEC_BALANCER_H_

struct __attribute__((refId("edu:umn:cs:melt:exts:ableC:parallel:exts:balancer:balancer"))) __balancer {
  int (*request_thread) (struct __balancer*, void* (*)(void*), void*);
  void (*demand_thread) (struct __balancer*, void* (*)(void*), void*);
  void (*yield_thread)  (struct __balancer*, void  (*)(void*), void*);
  void (*release_thread)(struct __balancer*);
  void* sysInfo;
};

#endif // ABLEC_BALANCER_H_
