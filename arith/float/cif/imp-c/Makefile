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

SRC = cif.c
EXE = cif

all:		$(EXE)

install:	$(EXE)

run-lzc32:	$(EXE)
		./$(EXE) -lzc32

run-rn-simple:		$(EXE)
		./$(EXE) -rn -simple

run-rn-selected:	$(EXE)
		./$(EXE) -rn -selected

run-rn-intervals:	$(EXE)
		./$(EXE) -rn -intervals

run-rn-specials:	$(EXE)
		cat special1.dat | \
		./$(EXE) -rn -server | \
		$(VER) -rnear_even -tininessbefore i32_to_f32

run-rn-extremes:	$(EXE)
		cat extreme1.dat | \
		./$(EXE) -rn -server | \
		$(VER) -rnear_even -tininessbefore i32_to_f32

run-rn-1M:	$(EXE)
		$(GEN) -n $(NUM_1M) -level $(LVL_1) i32 | \
		./$(EXE) -rn -server | \
		$(VER) -rnear_even -tininessbefore i32_to_f32

run-rn-10M:	$(EXE)
		$(GEN) -n $(NUM_10M) -level $(LVL_2) i32 | \
		./$(EXE) -rn -server | \
		$(VER) -rnear_even -tininessbefore i32_to_f32

run-rn-100M:	$(EXE)
		$(GEN) -n $(NUM_100M) -level $(LVL_2) i32 | \
		./$(EXE) -rn -server | \
		$(VER) -rnear_even -tininessbefore i32_to_f32

run-rn-1000M:	$(EXE)
		$(GEN) -n $(NUM_1000M) -level $(LVL_2) i32 | \
		./$(EXE) -rn -server | \
		$(VER) -rnear_even -tininessbefore i32_to_f32

run-rz-simple:		$(EXE)
		./$(EXE) -rz -simple

run-rz-selected:	$(EXE)
		./$(EXE) -rz -selected

run-rz-intervals:	$(EXE)
		./$(EXE) -rz -intervals

run-rz-specials:	$(EXE)
		cat special1.dat | \
		./$(EXE) -rz -server | \
		$(VER) -rminMag -tininessbefore i32_to_f32

run-rz-extremes:	$(EXE)
		cat extreme1.dat | \
		./$(EXE) -rz -server | \
		$(VER) -rminMag -tininessbefore i32_to_f32

run-rz-1M:	$(EXE)
		$(GEN) -n $(NUM_1M) -level $(LVL_1) i32 | \
		./$(EXE) -rz -server | \
		$(VER) -rminMag -tininessbefore i32_to_f32

run-rz-10M:	$(EXE)
		$(GEN) -n $(NUM_10M) -level $(LVL_2) i32 | \
		./$(EXE) -rz -server | \
		$(VER) -rminMag -tininessbefore i32_to_f32

run-rz-100M:	$(EXE)
		$(GEN) -n $(NUM_100M) -level $(LVL_2) i32 | \
		./$(EXE) -rz -server | \
		$(VER) -rminMag -tininessbefore i32_to_f32

run-rz-1000M:	$(EXE)
		$(GEN) -n $(NUM_1000M) -level $(LVL_2) i32 | \
		./$(EXE) -rz -server | \
		$(VER) -rminMag -tininessbefore i32_to_f32

run-rd-simple:		$(EXE)
		./$(EXE) -rd -simple

run-rd-selected:	$(EXE)
		./$(EXE) -rd -selected

run-rd-intervals:	$(EXE)
		./$(EXE) -rd -intervals

run-rd-specials:	$(EXE)
		cat special1.dat | \
		./$(EXE) -rd -server | \
		$(VER) -rmin -tininessbefore i32_to_f32

run-rd-extremes:	$(EXE)
		cat extreme1.dat | \
		./$(EXE) -rd -server | \
		$(VER) -rmin -tininessbefore i32_to_f32

run-rd-1M:	$(EXE)
		$(GEN) -n $(NUM_1M) -level $(LVL_1) i32 | \
		./$(EXE) -rd -server | \
		$(VER) -rmin -tininessbefore i32_to_f32

run-rd-10M:	$(EXE)
		$(GEN) -n $(NUM_10M) -level $(LVL_2) i32 | \
		./$(EXE) -rd -server | \
		$(VER) -rmin -tininessbefore i32_to_f32

run-rd-100M:	$(EXE)
		$(GEN) -n $(NUM_100M) -level $(LVL_2) i32 | \
		./$(EXE) -rd -server | \
		$(VER) -rmin -tininessbefore i32_to_f32

run-rd-1000M:	$(EXE)
		$(GEN) -n $(NUM_1000M) -level $(LVL_2) i32 | \
		./$(EXE) -rd -server | \
		$(VER) -rmin -tininessbefore i32_to_f32

run-ru-simple:		$(EXE)
		./$(EXE) -ru -simple

run-ru-selected:	$(EXE)
		./$(EXE) -ru -selected

run-ru-intervals:	$(EXE)
		./$(EXE) -ru -intervals

run-ru-specials:	$(EXE)
		cat special1.dat | \
		./$(EXE) -ru -server | \
		$(VER) -rmax -tininessbefore i32_to_f32

run-ru-extremes:	$(EXE)
		cat extreme1.dat | \
		./$(EXE) -ru -server | \
		$(VER) -rmax -tininessbefore i32_to_f32

run-ru-1M:	$(EXE)
		$(GEN) -n $(NUM_1M) -level $(LVL_1) i32 | \
		./$(EXE) -ru -server | \
		$(VER) -rmax -tininessbefore i32_to_f32

run-ru-10M:	$(EXE)
		$(GEN) -n $(NUM_10M) -level $(LVL_2) i32 | \
		./$(EXE) -ru -server | \
		$(VER) -rmax -tininessbefore i32_to_f32

run-ru-100M:	$(EXE)
		$(GEN) -n $(NUM_100M) -level $(LVL_2) i32 | \
		./$(EXE) -ru -server | \
		$(VER) -rmax -tininessbefore i32_to_f32

run-ru-1000M:	$(EXE)
		$(GEN) -n $(NUM_1000M) -level $(LVL_2) i32 | \
		./$(EXE) -ru -server | \
		$(VER) -rmax -tininessbefore i32_to_f32

$(EXE):		$(SRC)
		gcc -g -Wall -I$(INCDIR) -o $(EXE) $(SRC) $(LIB) -lm

clean:
		rm -f *~ $(EXE)
