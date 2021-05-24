all: blocking cilk lvars posix synchronization thrdpool server

blocking:
	$(MAKE) -C blocking

cilk:
	$(MAKE) -C cilk

lvars:
	$(MAKE) -C lvars

posix:
	$(MAKE) -C posix

synchronization:
	$(MAKE) -C synchronization

thrdpool:
	$(MAKE) -C thrdpool

server:
	$(MAKE) -C server

clean:
	$(MAKE) -C blocking clean
	$(MAKE) -C cilk clean
	$(MAKE) -C lvars clean
	$(MAKE) -C posix clean
	$(MAKE) -C synchronization clean
	$(MAKE) -C thrdpool clean
	$(MAKE) -C server clean

.PHONY: all build blocking cilk lvars posix synchronization thrdpool server clean

build:
	$(MAKE) -C blocking ableC.jar
	$(MAKE) -C cilk ableC.jar
	$(MAKE) -C lvars ableC.jar
	$(MAKE) -C posix ableC.jar
	$(MAKE) -C synchronization ableC.jar
	$(MAKE) -C thrdpool ableC.jar
	$(MAKE) -C server ableC.jar

