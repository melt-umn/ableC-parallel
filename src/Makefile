all: base cilk thrdpool

base:
	$(MAKE) -C base

cilk:
	$(MAKE) -C cilk

thrdpool:
	$(MAKE) -C thrdpool

clean:
	$(MAKE) -C base clean
	$(MAKE) -C cilk clean
	$(MAKE) -C thrdpool clean

.PHONY: all base cilk thrdpool clean
