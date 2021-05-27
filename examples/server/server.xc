#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>

#include <arpa/inet.h>
#include <sys/socket.h>
#include <netinet/ip.h>

#include <ableC_blocking.h>
#include <ableC_workstlr.h>
#include <ableC_posix.h>
#include <ableC_thrdpool.h>

#include "base64.h"
#include "networking.h"
#include "nqueens.h"

#define N_READERS 4
#define N_PROCESS 4
#define N_SEARCH 4
#define N_COUNT 4
#define N_WRITERS 4

/******************************************************************************
 * Bounded Buffer
 ******************************************************************************/
struct bounded_buffer {
  int head, tail, n, len;
  struct request** items;
};

typedef blocking synchronized<struct bounded_buffer> = {
  condition empty(this.n == 0);
  condition full(this.n >= this.len);

  when (this.n) += 1 then signal not empty;
  when (this.n) -= 1 then signal not full;
} bounded_buffer;

bounded_buffer* create_buffer(int len) {
  bounded_buffer* res = malloc(sizeof(bounded_buffer));
  if (res == NULL)
    return NULL;

  struct bounded_buffer tmp;
  tmp.head = 0; tmp.tail = 0; tmp.n = 0; tmp.len = len;
  tmp.items = malloc(sizeof(struct request*) * len);
  if (tmp.items == NULL) {
    free(res);
    return NULL;
  }

  *res = new bounded_buffer(tmp);
  return res;
}

void destroy_buffer(bounded_buffer* buffer) {
  holding (*buffer) as buf {
    free(buf.items);
  }

  delete *buffer;
  free(buffer);
}

struct request* buffer_get(bounded_buffer* buffer) {
  struct request* res;

  holding (*buffer) as buf {
    wait while buf.empty;

    res = buf.items[buf.head];
    buf.head = (buf.head + 1) % buf.len;
    buf.n -= 1;
  }

  return res;
}

void buffer_put(bounded_buffer* buffer, struct request* elem) {
  holding (*buffer) as buf {
    wait while buf.full;
    
    buf.items[buf.tail] = (void*) elem; // FIXME: Bug in types
    buf.tail = (buf.tail + 1) % buf.len;
    buf.n += 1;
  }
}

/******************************************************************************
 * NQueens
 ******************************************************************************/
int nqueens_find_next(const int n, chess_board* board, int iR, int iC, int goUp);

// Returns 1 on success, 0 if no next solution exists, and -1 if there's an 
// error
int nqueens_next(const int n, char* init) {
  // First we increment init
  for (int i = n - 1; i >= 0; i--) {
    int v = base64_to_int(init[i]) + 1;
    
    if (v < n) {
      init[i] = int_to_base64(v);
      break;
    } else {
      init[i] = '0';

      // If we reach the front and set everything to 0, we've hit the end
      if (i == 0)
        return 0;
    }
  }

  chess_board board;
  if (initialize_board(n, &board) == 0)
    return -1;

  // Now we determine how many of the rows specify a valid board configuration
  int valid_rows = load_board(n, init, &board);

  if (valid_rows == 0)
    return -1;

  int res =
    nqueens_find_next(n, &board, valid_rows, base64_to_int(init[valid_rows]), 1);
  if (res == 0) {
    destroy_board(&board);
    return 0;
  }

  memcpy(init, board.order, sizeof(char) * n);
  destroy_board(&board);
  return 1;
}

// Find the next solution starting in row iR and with column iC, traversing
// upward and changing already set rows if goUp = 1. Returns 1 on sucess and
// the board is updated to reflect the solution, otherwise returns 0 and the
// state of the board is undefined
int nqueens_find_next(const int n, chess_board* board, int iR, int iC, int goUp) {
  if (iR == n)
    return 1;

  const int posDiagonalBase = (n - 1) - iR;

  for (int c = iC; c < n; c++) {
    if (board->cols[c] == FILLED)
      continue;

    int posDiagonal = posDiagonalBase + c;
    int negDiagonal = iR + c;

    if (board->posDiagonal[posDiagonal] == FILLED
        || board->negDiagonal[negDiagonal] == FILLED)
      continue;

    board->cols[c] = FILLED;
    board->posDiagonal[posDiagonal] = FILLED;
    board->negDiagonal[negDiagonal] = FILLED;
    board->order[iR] = int_to_base64(c);

    if (nqueens_find_next(n, board, iR + 1, 0, 0) == 1) {
      return 1;
    }

    board->cols[c] = VACANT;
    board->posDiagonal[posDiagonal] = VACANT;
    board->negDiagonal[negDiagonal] = VACANT;
    board->order[iR] = 0;
  }
  
  // If nothing in this row produces a solution, try changing the previous row
  // if we're allowed to (the goUp variable is 1)
  // If this is the first row, we're done
  if (goUp) {
    if (iR == 0)
      return 0;

    // Column of previous row
    int pC = base64_to_int(board->order[iR-1]);
    int pR = iR - 1;

    board->cols[pC] = VACANT;
    board->posDiagonal[(n - 1) - pR + pC] = VACANT;
    board->negDiagonal[pR + pC] = VACANT;
    board->order[pR] = 0;

    return nqueens_find_next(n, board, pR, pC + 1, 1);
  } else {
    return 0;
  }
}

workstlr_func int count_helper(int n, chess_board* board, int r) {
  while (r < n && board->order[r] != '\0')
    r++;

  if (r == n) {
    destroy_board(board);
    free(board);
    return 1;
  }

  int posDiagonalBase = (n - 1) - r;
  // TODO: I'd like to have a += inlet to use, but for now...
  int* cnts = calloc(n, sizeof(int));
  for (int c = 0; c < n; c++) {
    if (board->cols[c] == FILLED) continue;

    int posDiagonal = posDiagonalBase + c;
    int negDiagonal = r + c;

    if (board->posDiagonal[posDiagonal] == FILLED
        || board->negDiagonal[negDiagonal] == FILLED)
      continue;

    chess_board* new_board = malloc(sizeof(chess_board));
    if (new_board == NULL || initialize_board(n, new_board) != 1) exit(50);
    if (copy_board(board, new_board) != 1) exit(50);
    new_board->cols[c] = FILLED;
    new_board->posDiagonal[posDiagonal] = FILLED;
    new_board->negDiagonal[negDiagonal] = FILLED;
    new_board->order[r] = int_to_base64(c);

    spawn cnts[c] = count_helper(n, new_board, r+1);
  }
  sync;

  int cnt = 0;
  for (int i = 0; i < n; i++)
    cnt += cnts[i];
  free(cnts);

  destroy_board(board);
  free(board);
  return cnt;
}

workstlr_func int count_nqueens(int n, char* init) {
  chess_board* board = malloc(sizeof(chess_board));
  if (board == NULL || initialize_board(n, board) != 1) exit(50);

  // If the initial configuration is invalid, there are 0 solutions
  if (construct_board(n, init, board) == 0) return 0;

  int res;
  spawn res = count_helper(n, board, 0);
  sync;

  return res;
}

/******************************************************************************
 * Server Interface
 ******************************************************************************/
int sockfd;
bounded_buffer* to_deliver;

thrdpool parallel processing;
thrdpool parallel searching;
workstlr parallel counting;

void handle_request(struct request* req);

void read_thread() {
  int res;
  struct request* req;

  posix group grp; grp = new posix group();

  while (1) {
    req = accept_request(sockfd);
    if (req == NULL) {
      perror("accept_request failed:");
      exit(-1);
    }

    res = process_request(req);
    if (res == -2) { // Shutdown message
      close_request(req);
      break;
    } else if (res == -1) { // Bad message
      send_response(req, "Invalid Message", 15);
      close_request(req);
      continue;
    }

    spawn handle_request(req); by processing; in grp; private req; global handle_request;
  }

  sync grp;
  delete grp;
}

void handle_request(struct request* req) {
  int n = req->n;
  
  blocking thread thd; thd = new blocking thread();

  if (req->type == '>') { // Find next solution
    int res;
    spawn res = nqueens_next(n, req->data); by searching; as thd; global nqueens_next; private n; private req; public res;
    sync thd;

    if (res == 0) { // No solution found
      free(req->data);
      req->data = NULL;
    } else if (res == -1) { // An error occured
      // Set message to ??...?? to signal error
      for (int i = 0; i < n; i++) {
        req->data[i] = '?';
      }
    }
  } else { // Count solutions

    int count;
    spawn count = count_nqueens(n, req->data); by counting; as thd;
    sync thd;

    free(req->data);
    req->data = malloc(sizeof(int));
    *((int*) req->data) = count;
  }

  delete thd;
  buffer_put(to_deliver, req);
}

void write_thread() {
  struct request* req;

  while (1) {
    req = buffer_get(to_deliver);
    if (req == NULL) { // Shutdown message
      break;
    }

    if (req->type == '>') {
      if (req->data == NULL) { // No further solution found
        send_response(req, "No Further Solutions", 20);
      } else {
        send_response(req, req->data, req->n);
      }
    } else {
      send_response(req, req->data, sizeof(int));
    }

    close_request(req);
  }
}

int main() {
  sockfd = setup_socket();
  
  if (sockfd == -1) {
    fprintf(stderr, "Failed to initialize socket\n");
    exit(1);
  }
  
  to_deliver = create_buffer(100);

  processing = new thrdpool parallel(N_PROCESS);
  searching = new thrdpool parallel(N_SEARCH);
  counting = new workstlr parallel(N_COUNT);

  posix parallel threads = new posix parallel();
  posix group readers; readers = new posix group();
  posix group writers; writers = new posix group();

  parallel for (int i = 0; i < N_WRITERS; i++) { by threads; in writers; num-threads N_WRITERS; global write_thread;
    write_thread();
  }
  parallel for (int i = 0; i < N_READERS; i++) { by threads; in readers; num-threads N_READERS; global read_thread;
    read_thread();
  }

  char msg[4];
  msg[0] = '\0';
  do {
    int res = read(0, msg, 4);
    if (res != 4) msg[0] = '\0';
  } while (msg[0] != 'q' || msg[1] != 'u' && msg[2] != 'i' || msg[3] != 't')

  printf("Beginning shutdown\n");

  // Shutdown Procedure
  //    Open one connection to the server for each thread reading requests, and
  //    transmit a null byte, this signals to the thread it should shutdown
  //    (obviously not secure)
  //
  //    Synchronize waiting for the reading threads to be done. They, in turn,
  //    wait on all the requests they read to be finished, and then they 
  //    return.
  //
  //    Place one NULL into the to_deliver bounded buffer for each thread in the
  //    delivery system, they take these and interpret them as commands to exit.
  //    Wait for them to all exit. Finally, close the socket and the server is
  //    shutdown properly.
  
  for (int i = 0; i < N_READERS; i++) {
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd == -1) {
      fprintf(stderr, "socket failed during shutdown\n");
      exit(2);
    }
   
    struct sockaddr_in servaddr;
    memset(&servaddr, 0, sizeof(servaddr));
  
    servaddr.sin_family = AF_INET;
    servaddr.sin_addr.s_addr = inet_addr("127.0.0.1");
    servaddr.sin_port = htons(PORT);
  
    if (connect(fd, (struct sockaddr*) &servaddr, sizeof(servaddr)) != 0) { 
      fprintf(stderr, "connect failed during shutdown\n");
      exit(3);
    }
    if (write(fd, "\0", 1) != 1) {
      fprintf(stderr, "write failed during shutdown\n");
      exit(4);
    }
    close(fd);
  }

  sync readers;
  delete readers;

  for (int i = 0; i < N_WRITERS; i++) {
    buffer_put(to_deliver, NULL);
  }

  sync writers;
  delete writers;

  delete threads;
  delete processing; // Stops the processing pool
  delete searching; // Stops the searching pool
  delete counting; // Stops the work stealer pool

  destroy_buffer(to_deliver);

  close(sockfd);

  return 0;
}
