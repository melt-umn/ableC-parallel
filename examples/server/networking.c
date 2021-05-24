#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/ip.h>

#include "base64.h"
#include "networking.h"

int setup_socket() {
  int fd;

  if ((fd = socket(AF_INET, SOCK_STREAM, 0)) == -1)
    return -1;

  struct sockaddr_in servaddr;
  memset(&servaddr, 0, sizeof(servaddr));
  servaddr.sin_family = AF_INET;
  servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
  servaddr.sin_port = htons(PORT);

  if (bind(fd, (struct sockaddr*) &servaddr, sizeof(servaddr)) == -1) {
    close(fd);
    return -1;
  }

  if (listen(fd, 50) == -1) {
    close(fd);
    return -1;
  }

  return fd;
}

struct request* accept_request(int sockfd) {
  int fd;
  
  if ((fd = accept(sockfd, NULL, NULL)) == -1)
    return NULL;

  struct request* res = malloc(sizeof(struct request));
  res->fd = fd;
  res->data = NULL;
  
  return res;
}

int process_request(struct request* req) {
  char first, base64_n;

  const int fd = req->fd;

  if (read(fd, &first, sizeof(char)) != sizeof(char))
    return -1;
  if (first == '\0')
    return -2;

  if (first != '#' && first != '>')
    return -1;

  if (read(fd, &base64_n, sizeof(char)) != sizeof(char))
    return -1;

  if (!valid_base64(base64_n))
    return -1;

  const int n = base64_to_int(base64_n);

  req->n = n;
  req->type = first;

  const int spaceValid = first == '#';

  char* initial = malloc(sizeof(char) * n);
  if (initial == NULL)
    return -1;

  size_t want = n;
  size_t have = 0;
  while (have < want) {
    size_t res = read(fd, initial + have, want - have);

    // < 0 is an error, I believe = 0 is efo
    if (res <= 0) {
      free(initial);
      return -1;
    }

    have += res;
  }

  for (int i = 0; i < n; i++) {
    if (!valid_base64(initial[i]) && (initial[i] != ' ' || !spaceValid)) {
      free(initial);
      return -1;
    }
  }

  req->data = initial;
  return 0;
}

int send_response(struct request* req, char* res, int len) {
  const int fd = req->fd;

  if (write(fd, &len, sizeof(int)) != sizeof(int)) {
    return -1;
  }

  size_t want = len;
  size_t wrote = 0;

  while (wrote < want) {
    size_t ret = write(fd, res + wrote, want - wrote);

    // < 0 is error, = 0 is eof (actually might be an error in this case)
    if (ret <= 0) {
      return -1;
    }

    wrote += ret;
  }

  return 0;
}

void close_request(struct request* req) {
  close(req->fd);

  if (req->data != NULL) free(req->data);
  free(req);
}
