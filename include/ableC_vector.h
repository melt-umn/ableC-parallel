#ifndef INCLUDE_ABLEC_PARALLEL_VECTOR_H_
#define INCLUDE_ABLEC_PARALLEL_VECTOR_H_

#include <ableC_parallel.h>

// An easier to use aligned malloc than the POSIX version
void* aligned_malloc(size_t alignment, size_t size) {
  void* res = NULL;
  posix_memalign(&res, alignment, size);
  return res;
}

// Typedef a bunch of 256 bit vector types (since these are the size of AVX
// registers, there is a AVX-512 extension, but I haven't actually found a
// machine with it)
// Later work could support expanding this to other sizes, based on the target
// machine.

// 32 bytes = 256 bits
typedef signed char vecSChar __attribute__((vector_size(32)));
typedef unsigned char vecUChar __attribute__((vector_size(32)));

typedef signed short vecSShort __attribute__((vector_size(32)));
typedef unsigned short vecUShort __attribute__((vector_size(32)));

typedef signed int vecSInt __attribute__((vector_size(32)));
typedef unsigned int vecUInt __attribute__((vector_size(32)));

typedef signed long vecSLong __attribute__((vector_size(32)));
typedef unsigned long vecULong __attribute__((vector_size(32)));

typedef signed long long vecSLLong __attribute__((vector_size(32)));
typedef unsigned long long vecULLong __attribute__((vector_size(32)));

typedef float vecFloat __attribute__((vector_size(32)));
typedef double vecDouble __attribute__((vector_size(32)));

#endif // INCLUDE_ABLEC_PARALLEL_VECTOR_H_
