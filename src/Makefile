all: base workstlr thrdpool bthrdpool bworkstlr

base:
	$(MAKE) -C base

workstlr:
	$(MAKE) -C workstlr

thrdpool:
	$(MAKE) -C thrdpool

bthrdpool:
	$(MAKE) -C bthrdpool

bworkstlr:
	$(MAKE) -C bworkstlr

clean:
	$(MAKE) -C base clean
	$(MAKE) -C workstlr clean
	$(MAKE) -C thrdpool clean
	$(MAKE) -C bthrdpool clean
	$(MAKE) -C bworkstlr clean

.PHONY: all base workstlr thrdpool bthrdpool bworkstlr clean
