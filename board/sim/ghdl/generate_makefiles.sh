#!/usr/bin/env bash

for file in `cat compile_order.txt`
do
	ghdl -a --std=08 -O3 "$file"
done

ghdl gen-makefile --std=08 nes_bench | sed -e 's/GHDLFLAGS= --std=08$/GHDLFLAGS= --std=08 -O3/g' > nes_bench.Makefile
ghdl gen-makefile --std=08 ppu_bench | sed -e 's/GHDLFLAGS= --std=08$/GHDLFLAGS= --std=08 -O3/g' > ppu_bench.Makefile
ghdl gen-makefile --std=08 nsf_bench | sed -e 's/GHDLFLAGS= --std=08$/GHDLFLAGS= --std=08 -O3/g' > nsf_bench.Makefile

