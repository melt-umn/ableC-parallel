all: blocking cilk lvars posix synchronization thrdpool server

libs:
	$(MAKE) -C ../src

build:
	$(MAKE) -C server ableC.jar

blocking: libs
	$(MAKE) -C blocking

cilk: libs
	$(MAKE) -C cilk

lvars: libs
	$(MAKE) -C lvars

posix: libs
	$(MAKE) -C posix

synchronization: libs
	$(MAKE) -C synchronization

thrdpool: libs
	$(MAKE) -C thrdpool

server: libs
	$(MAKE) -C server

clean:
	$(MAKE) -C blocking clean
	$(MAKE) -C cilk clean
	$(MAKE) -C lvars clean
	$(MAKE) -C posix clean
	$(MAKE) -C synchronization clean
	$(MAKE) -C thrdpool clean
	$(MAKE) -C server clean

.PHONY: all build blocking cilk lvars posix synchronization thrdpool server clean libs
