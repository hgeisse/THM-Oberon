#
# Makefile for implementation and test of floating-point arithmetic
#

BUILD = ../../../../build

# number of test cases
NUM_1M = 1000000
NUM_10M = 10000000
NUM_100M = 100000000
NUM_1000M = 1000000000

# test level (1 or 2)
LVL_1 = 1
LVL_2 = 2

INCDIR = ../../test/include
LIB = ../../test/lib/softfloat.a

GEN = ../../test/bin/testfloat_gen
VER = ../../test/bin/testfloat_ver

SRC = sqr.c
EXE = sqr

all:		$(EXE)

install:	$(EXE)

run-sqr24:	$(EXE)
		./$(EXE) -sqr24

run-lzc24:	$(EXE)
		./$(EXE) -lzc24

run-simple:	$(EXE)
		./$(EXE) -simple

run-selected:	$(EXE)
		./$(EXE) -selected

run-intervals:	$(EXE)
		./$(EXE) -intervals

run-specials:	$(EXE)
		cat special1.dat | \
		./$(EXE) -server | \
		$(VER) -rnear_even -tininessbefore f32_sqrt

run-extremes:	$(EXE)
		cat extreme1.dat | \
		./$(EXE) -server | \
		$(VER) -rnear_even -tininessbefore f32_sqrt

run-1M:		$(EXE)
		$(GEN) -n $(NUM_1M) -level $(LVL_1) i32 | \
		./$(EXE) -server | \
		$(VER) -rnear_even -tininessbefore f32_sqrt

run-10M:	$(EXE)
		$(GEN) -n $(NUM_10M) -level $(LVL_2) i32 | \
		./$(EXE) -server | \
		$(VER) -rnear_even -tininessbefore f32_sqrt

run-100M:	$(EXE)
		$(GEN) -n $(NUM_100M) -level $(LVL_2) i32 | \
		./$(EXE) -server | \
		$(VER) -rnear_even -tininessbefore f32_sqrt

run-1000M:	$(EXE)
		$(GEN) -n $(NUM_1000M) -level $(LVL_2) i32 | \
		./$(EXE) -server | \
		$(VER) -rnear_even -tininessbefore f32_sqrt

$(EXE):		$(SRC)
		gcc -g -Wall -I$(INCDIR) -o $(EXE) $(SRC) $(LIB) -lm

clean:
		rm -f *~ $(EXE)