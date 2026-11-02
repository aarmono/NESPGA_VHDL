#!/usr/bin/env bash

for file in `cat compile_order.txt`
do
	ghdl -a --std=08 -O3 -fsynopsys "$file"
done

# Writes the makefile from ghdl gen-makefile "$@" to stdout, adding -O3 to the
# flags. The makefile is filtered to not depend on ghdl's prebuilt libraries in
# /opt/ghdl, whose rules can only fail with "This file was not locally built":
# with them, make fails whenever an image has a library source newer than the
# library
gen_makefile() {
	ghdl gen-makefile "$@" |
		sed -e 's/^GHDLFLAGS=.*$/& -O3/' \
		    -e '/^\/opt\/ghdl\//d' \
		    -e '/^\t@echo "This file was not locally built/,/^\texit 1$/d' \
		    -e 's| /opt/ghdl/[^ ]*||g'
}

gen_makefile --std=08 nes_bench > nes_bench.Makefile
gen_makefile --std=08 ppu_bench > ppu_bench.Makefile

gen_makefile --std=08 sdram_rom_bench > sdram_rom_bench.Makefile
gen_makefile --std=08 sd_menu_bench > sd_menu_bench.Makefile

gen_makefile --std=08 frame_lock_bench > frame_lock_bench.Makefile

gen_makefile --std=08 -fsynopsys nes_de1_bench > nes_de1_bench.Makefile
