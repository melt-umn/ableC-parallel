#include <stdio.h>
#include <ableC_vector.h>

int main() {
  int* j;

  vectorize parallel vect = new vectorize parallel();
  
  parallel for (int i = 1; i < 10; i++) { by vect;
    j[i] = j[i-1] + 1;
  }
}
