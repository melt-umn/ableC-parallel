.NOTPARALLEL:
all: base fcfs bthrdpool bworkstlr blocking cilk workstlr lvars posix synchronization thrdpool vector mapReduce

base:
	$(MAKE) -C base

fcfs:
	$(MAKE) -C fcfs

bthrdpool:
	$(MAKE) -C bthrdpool

bworkstlr:
	$(MAKE) -C workstlr

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

mda:
	$(MAKE) -C base mda
	$(MAKE) -C fcfs mda
	$(MAKE) -C bthrdpool mda
	$(MAKE) -C bworkstlr mda
	$(MAKE) -C blocking mda
	$(MAKE) -C workstlr mda
	$(MAKE) -C lvars mda
	$(MAKE) -C posix mda
	$(MAKE) -C synchronization mda
	$(MAKE) -C thrdpool mda
	$(MAKE) -C vector mda
	$(MAKE) -C mapReduce mda

mwda:
	$(MAKE) -C base mwda
	$(MAKE) -C fcfs mwda
	$(MAKE) -C bthrdpool mwda
	$(MAKE) -C bworkstlr mwda
	$(MAKE) -C blocking mwda
	$(MAKE) -C workstlr mwda
	$(MAKE) -C lvars mwda
	$(MAKE) -C posix mwda
	$(MAKE) -C synchronization mwda
	$(MAKE) -C thrdpool mwda
	$(MAKE) -C vector mwda
	$(MAKE) -C mapReduce mwda

clean:
	$(MAKE) -C base clean
	$(MAKE) -C fcfs clean
	$(MAKE) -C bthrdpool clean
	$(MAKE) -C bworkstlr clean
	$(MAKE) -C blocking clean
	$(MAKE) -C workstlr clean
	$(MAKE) -C lvars clean
	$(MAKE) -C posix clean
	$(MAKE) -C synchronization clean
	$(MAKE) -C thrdpool clean
	$(MAKE) -C vector clean
	$(MAKE) -C mapReduce clean

.PHONY: all base fcfs bthrdpool bworkstlr blocking cilk workstlr lvars posix synchronization thrdpool vector mapReduce clean mda mwda
