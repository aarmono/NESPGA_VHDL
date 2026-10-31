# Assembles the boot stub of ROM_SD_MENU and makes the VHDL package that
# holds it, ../sd_menu_stub.vhdl, which is checked in so that the simulation
# and Quartus builds do not need cc65. stub.nes is the stub's image as
# sd_menu streams it, for stub_test.sh. menu.nes is the menu, which goes on
# the card as MENU.NES. make sd_card.img makes a card image holding it (see
# sd_image.sh). make smoke_card.img makes the card of the nes_de1_bench
# smoke test (../../sim/ghdl/sd_menu_tests.txt)

CA65 ?= ca65
LD65 ?= ld65
PYTHON ?= python3 -B

all: ../sd_menu_stub.vhdl menu.nes

%.o: %.s fat.inc
	$(CA65) $< -o $@ -l $*.lst

menu.o save.o: menu.inc

stub.bin: stub.o fat.o stub.cfg
	$(LD65) -C stub.cfg -o $@ -m stub.map stub.o fat.o

font.chr: font.py
	$(PYTHON) font.py $@

menu.o: font.chr

menu.nes: menu.o save.o fat.o menu.cfg
	$(LD65) -C menu.cfg -o $@ -m menu.map menu.o save.o fat.o

../sd_menu_stub.vhdl stub.nes &: stub.bin stub_rom.py
	$(PYTHON) stub_rom.py stub.bin ../sd_menu_stub.vhdl --nes stub.nes

sd_card.img: menu.nes sd_image.sh
	./sd_image.sh $@

# 4 MB FAT16 with no partition table and a fixed volume ID, holding MENU.NES
# and one game under a long name. MENU.NES is not listed, so the game is the
# menu's first entry
SMOKE_GAME ?= ../../../nes-test-roms/instr_test-v5/rom_singles/01-basics.nes
SMOKE_NAME ?= Instruction Test 01 - Basics.nes

smoke_card.img: menu.nes $(SMOKE_GAME)
	rm -f $@
	PATH=$$PATH:/usr/sbin:/sbin mkfs.fat -C -F 16 -s 1 -i 4E455350 $@ 4096 \
		> /dev/null
	MTOOLS_SKIP_CHECK=1 mcopy -i $@ menu.nes ::/MENU.NES
	MTOOLS_SKIP_CHECK=1 mcopy -i $@ $(SMOKE_GAME) "::/$(SMOKE_NAME)"

clean:
	rm -f *.o *.lst stub.bin stub.map stub.nes font.chr menu.map menu.nes \
		sd_card.img sd_card.img.gz smoke_card.img

.PHONY: all clean
