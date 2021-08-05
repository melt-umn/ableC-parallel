#include <stdio.h>
#include <ableC_vector.h>

int main() {
  int j;

  vectorize parallel vect = new vectorize parallel();
  
  parallel for (int i = 0; i < 10; i++) { by vect;
    j += 1;
  }
}
