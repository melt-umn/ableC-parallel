# These can safely run in parallel, sicne all the recusive makes invoke silver with --dont-translate
# TODO: There is probably a nicer way to organize this Makefile...

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

base_mda:
	$(MAKE) -C base mda

fcfs_mda:
	$(MAKE) -C fcfs mda

bthrdpool_mda:
	$(MAKE) -C bthrdpool mda

bworkstlr_mda:
	$(MAKE) -C workstlr mda

blocking_mda:
	$(MAKE) -C blocking mda

cilk_mda:
	$(MAKE) -C cilk mda

workstlr_mda:
	$(MAKE) -C workstlr mda

lvars_mda:
	$(MAKE) -C lvars mda

posix_mda:
	$(MAKE) -C posix mda

synchronization_mda:
	$(MAKE) -C synchronization mda

thrdpool_mda:
	$(MAKE) -C thrdpool mda

vector_mda:
	$(MAKE) -C vector mda

mapReduce_mda:
	$(MAKE) -C mapReduce mda

mda: base_mda fcfs_mda bthrdpool_mda bworkstlr_mda blocking_mda cilk_mda workstlr_mda lvars_mda posix_mda synchronization_mda thrdpool_mda vector_mda mapReduce_mda

# TODO: No reason to run MWDA seperately for every extension here...
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
