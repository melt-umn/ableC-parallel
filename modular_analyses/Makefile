all: base blocking cilk lvars posix synchronization thrdpool

base:
	$(MAKE) -C base

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

clean:
	$(MAKE) -C base clean
	$(MAKE) -C blocking clean
	$(MAKE) -C cilk clean
	$(MAKE) -C lvars clean
	$(MAKE) -C posix clean
	$(MAKE) -C synchronization clean
	$(MAKE) -C thrdpool clean

.PHONY: all base blocking cilk lvars posix synchronization thrdpool clean
