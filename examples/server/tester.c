#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <arpa/inet.h>
#include <sys/socket.h>
#include <netinet/ip.h>

int main() {
  char buffer[67];

  while (1) {
    if (fgets(buffer, 67, stdin) == NULL) {
      break;
    }

    int len = strlen(buffer);
    if (buffer[len-1] == '\n')
      len--;

    int resInt = buffer[0] == '#';

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

      wrote += res;
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

    if (resInt) {
      int res = *((int*) buffer);
      printf("%d\n\n", res);
    } else {
      write(1, buffer, length);
      printf("\n\n");
    }

    close(fd);
  }

  return 0;
}
