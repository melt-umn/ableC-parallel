.NOTPARALLEL:
all: base blocking cilk workstlr lvars posix synchronization thrdpool vector mapReduce

base:
	$(MAKE) -C base

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

clean:
	$(MAKE) -C base clean
	$(MAKE) -C blocking clean
	$(MAKE) -C workstlr clean
	$(MAKE) -C lvars clean
	$(MAKE) -C posix clean
	$(MAKE) -C synchronization clean
	$(MAKE) -C thrdpool clean
	$(MAKE) -C vector clean
	$(MAKE) -C mapReduce clean

.PHONY: all base blocking cilk workstlr lvars posix synchronization thrdpool vector mapReduce clean
