#!/usr/bin/env bash

for file in `cat compile_order.txt`
do
	ghdl -a --std=08 -O3 -fsynopsys "$file"
done

ghdl gen-makefile --std=08 nes_bench | sed -e 's/^GHDLFLAGS=.*$/& -O3/' > nes_bench.Makefile
ghdl gen-makefile --std=08 ppu_bench | sed -e 's/^GHDLFLAGS=.*$/& -O3/' > ppu_bench.Makefile

ghdl gen-makefile --std=08 sdram_rom_bench | sed -e 's/^GHDLFLAGS=.*$/& -O3/' > sdram_rom_bench.Makefile
ghdl gen-makefile --std=08 sd_menu_bench | sed -e 's/^GHDLFLAGS=.*$/& -O3/' > sd_menu_bench.Makefile

ghdl gen-makefile --std=08 -fsynopsys nes_de1_bench | sed -e 's/^GHDLFLAGS=.*$/& -O3/' > nes_de1_bench.Makefile

