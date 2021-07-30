#ifndef INCLUDE_NETWORKING_H_
#define INCLUDE_NETWORKING_H_

#define PORT 8080

// Returns a file-descriptor for a socket, or -1 if an error occurs
int setup_socket();

struct request {
  int fd, n;
  char type;
  char* data;
};

// Accepts a request coming into the socket provided. Allocates a structure
// and stores the file-descriptor into it. Does not read any of the message
struct request* accept_request(int sockfd);

// Accepts a request as produced by the accept_request function and reads from
// the file descriptor to determine what the request is asking for.
// The message is expected to match the following regex:
//    [>#][0-9a-zA-Z!@\ ]+
// specifically, the first character specifies the type of request (> asks for
// the next solution for a given n and starting state and # asks for the number
// of solutions for a given n and starting state). The next character is a
// base64 encoding of n. Then the message contains n additional characters,
// in base64 (or a space if the first character is a #) encoding a starting
// state.
//
// Returns 0 on success and updates the request and returns -1 on a failure,
// unless the first byte is a null-byte in which case it returns -2. On an
// error the state of the request is undefined except that the fd field is
// unchanged
int process_request(struct request* req);

// Sends the specified number of bytes from the res string back on the file
// descriptor associated with the provided request. The first four bytes of
// the message are the length of the message (in host byte-order)
// Returns 0 on success and -1 on failure
int send_response(struct request* req, char* res, int len);

// Closes the file descriptor associated with the request, and frees any
// allocated memory associated with it (including the memory storing the request
// itself)
void close_request(struct request* req);

#endif
