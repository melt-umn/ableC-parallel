all: blocking cilk workstlr lvars posix synchronization thrdpool vector mapReduce server

blocking:
	$(MAKE) -C blocking

cilk:
	$(MAKE) -C cilk

workstlr:
	$(MAKE) -C workstlr

lvars:
	$(MAKE) -C lvars

posix:
	$(MAKE) -C posix

synchronization:
	$(MAKE) -C synchronization

thrdpool:
	$(MAKE) -C thrdpool

vector:
	$(MAKE) -C vector

mapReduce:
	$(MAKE) -C mapReduce

server:
	$(MAKE) -C server

clean:
	$(MAKE) -C blocking clean
	$(MAKE) -C cilk clean
	$(MAKE) -C workstlr clean
	$(MAKE) -C lvars clean
	$(MAKE) -C posix clean
	$(MAKE) -C synchronization clean
	$(MAKE) -C thrdpool clean
	$(MAKE) -C vector clean
	$(MAKE) -C mapReduce clean
	$(MAKE) -C server clean

.PHONY: all build blocking cilk workstlr lvars posix synchronization thrdpool vector mapReduce server clean

build:
	$(MAKE) -C blocking ableC.jar
	$(MAKE) -C cilk ableC.jar
	$(MAKE) -C workstlr ableC.jar
	$(MAKE) -C lvars ableC.jar
	$(MAKE) -C posix ableC.jar
	$(MAKE) -C synchronization ableC.jar
	$(MAKE) -C thrdpool ableC.jar
	$(MAKE) -C vector ableC.jar
	$(MAKE) -C mapReduce ableC.jar
	$(MAKE) -C server ableC.jar

