// This is the stress tester, it generates semi-random requests from a number of
// threads and records the requests and results for later checking.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <arpa/inet.h>
#include <sys/socket.h>
#include <netinet/ip.h>
#include <omp.h>

#include "base64.h"

#define NUM_THREADS 4
#define NUM_REQUESTS 10 // Requests per thread

int main() {
  // You know, this is the first time I've ever thought this construct was useful
  #pragma omp parallel num_threads(NUM_THREADS)
  {
    unsigned int seed = omp_get_thread_num();
    
    char buffer[67];
    snprintf(buffer, sizeof(buffer), "reqs_%u.in", seed);
    FILE* requestFile = fopen(buffer, "w");
    snprintf(buffer, sizeof(buffer), "res_%u.out", seed);
    FILE* resultFile = fopen(buffer, "w");

    for (int i = 0; i < NUM_REQUESTS; i++) {
      // Randomly pick between count (#) and next (>) operation
      buffer[0] = rand_r(&seed) % 2 == 0 ? '#' : '>';

      int n_limit = buffer[0] == '#' ? 15 : 20;
      int n = rand_r(&seed) % n_limit + 1;
      buffer[1] = int_to_base64(n);

      if (buffer[0] == '>') {
        for (int j = 0; j < n; j++) {
          buffer[2+j] = int_to_base64(rand_r(&seed) % n);
        }
      } else {
        for (int j = 0; j < n; j++) {
          buffer[2+j] = ' ';
        }

        int give = rand_r(&seed) % 4;
        for (int i = 0; i < give; i++) {
          int r = rand_r(&seed) % n;
          int c = rand_r(&seed) % n;
          buffer[2+r] = int_to_base64(c);
        }
      }

      int len = 2 + n;
      int resInt = (buffer[0] == '#');

      fwrite(buffer, len, 1, requestFile);
      fprintf(requestFile, "\n");
      fflush(requestFile);
      
      int fd = socket(AF_INET, SOCK_STREAM, 0);
      if (fd == -1) {
        fprintf(stderr, "Failed to open socket\n");
        exit(1);
      }

      struct sockaddr_in servaddr;
      memset(&servaddr, 0, sizeof(servaddr));

      servaddr.sin_family = AF_INET;
      servaddr.sin_addr.s_addr = inet_addr("127.0.0.1");
      servaddr.sin_port = htons(8080);

      if (connect(fd, (struct sockaddr*) &servaddr, sizeof(servaddr)) != 0) {
        fprintf(stderr, "Failed to connect to server\n");
        exit(2);
      }

      size_t want = len;
      size_t wrote = 0;
      while (wrote < want) {
        size_t res = write(fd, buffer + wrote, want - wrote);
        if (res <= 0) {
          fprintf(stderr, "Error while writing\n");
          exit(3);
        }

        wrote += 3;
      }

      int length;
      if (read(fd, &length, sizeof(int)) != sizeof(int)) {
        fprintf(stderr, "Error while reading size\n");
        exit(4);
      }

      size_t got = 0;
      while (got < length) {
        size_t res = read(fd, buffer + got, length - got);
        if (res <= 0) {
          fprintf(stderr, "Error while reading body\n");
          exit(5);
        }
        got += res;
      }
      
      close(fd);

      if (resInt) {
        int res = *((int*) buffer);
        fprintf(resultFile, "%d\n", res);
      } else {
        fwrite(buffer, length, 1, resultFile);
        fprintf(resultFile, "\n");
      }
    }

    fclose(requestFile);
    fclose(resultFile);
  }
}
