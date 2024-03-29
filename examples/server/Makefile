# Path from current directory to top level ableC repository
ABLEC_BASE?=../../../../ableC
# Path from current directory to top level extensions directory
EXTS_BASE?=../../../../extensions

# The jar file to use
ABLEC_JAR=../ableC.jar

# All extended C files to compile
XC_FILES=$(wildcard *.xc)
# All C files that should be generated
C_FILES=$(XC_FILES:.xc=.c)
# All object files that should be generated
OBJECTS=$(XC_FILES:.xc=.o)
# All executables that should be generated
EXECUTABLES=$(XC_FILES:.xc=.out)
# All evaluation marker files that should be generated
TESTS=$(XC_FILES:.xc=.test)

# All directories contining extension header files that may be included
XC_INCLUDE_DIRS=$(wildcard $(EXTS_BASE)/*/include)
# All header files that may be included, to be included as dependencies
XC_INCLUDE_SOURCES=$(foreach dir,$(XC_INCLUDE_DIRS),$(wildcard $(dir)/*.*h))
# Flags passed to ableC including the appropriate directories
override XCFLAGS+=$(addprefix -I,$(XC_INCLUDE_DIRS))
# Flags passed to Java when invoking ableC
override JAVAFLAGS+=-Xss6M

# Flags passed to the C compiler, e.g. to enable various compiler extensions
override CFLAGS+=-ggdb

# All directories contining extension libraries that may be linked
LIB_DIRS=$(wildcard $(EXTS_BASE)/*/lib)
# Flags passed to the linker specifying the appropriate directories
override LDFLAGS+=-ggdb $(addprefix -L,$(LIB_DIRS)) 
# Flags passed to the linker specifying libraries to link
# Specify ableC_parallel and ableC_parallel_thrdpool is to be linked statically, everything 
# else dynamically
LDLIBS=-Wl,-Bstatic -lableC_parallel -lableC_parallel_thrdpool -lableC_parallel_workstlr -Wl,-Bdynamic -lpthread

# All directories contining extension library sources
SRC_DIRS=$(wildcard $(EXTS_BASE)/*/src)
# All extension library targets
LIBS=$(SRC_DIRS:src=libs)
# All C files used to build libraries, to be included as dependencies
SRC_SOURCES=$(foreach dir,$(SRC_DIRS),$(wildcard $(dir)/*.c))

all: server.out tester.out stress.out

server.c: server.xc base64.h networking.h nqueens.h $(XC_INCLUDE_SOURCES) $(ABLEC_JAR)
	java $(JAVAFLAGS) -jar $(ABLEC_JAR) $< $(XCFLAGS)

server.out: server.o networking.o nqueens.o $(SRC_SOURCES) | libs
	$(CC) $(LDFLAGS) $< networking.o nqueens.o $(LDLIBS) -o $@

tester.out: tester.c
	$(CC) -g tester.c -o tester.out

stress.out: stress.c
	$(CC) -g stress.c -fopenmp -o stress.out

clean:
	rm -f *~ *.i server.c *.o *.out *.in

.PHONY: all libs $(LIBS) clean
