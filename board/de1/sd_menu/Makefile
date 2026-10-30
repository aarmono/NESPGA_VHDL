# Assembles the boot stub of ROM_SD_MENU and makes the VHDL package that
# holds it, ../sd_menu_stub.vhdl, which is checked in so that the simulation
# and Quartus builds do not need cc65. stub.nes is the stub's image as
# sd_menu streams it, for stub_test.sh

CA65 ?= ca65
LD65 ?= ld65
PYTHON ?= python3 -B

all: ../sd_menu_stub.vhdl

stub.o: stub.s
	$(CA65) $< -o $@ -l stub.lst

stub.bin: stub.o stub.cfg
	$(LD65) -C stub.cfg -o $@ -m stub.map stub.o

../sd_menu_stub.vhdl stub.nes &: stub.bin stub_rom.py
	$(PYTHON) stub_rom.py stub.bin ../sd_menu_stub.vhdl --nes stub.nes

clean:
	rm -f stub.o stub.lst stub.bin stub.map stub.nes

.PHONY: all clean
