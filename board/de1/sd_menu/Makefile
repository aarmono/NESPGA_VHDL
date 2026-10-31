# Assembles the boot stub of ROM_SD_MENU and makes the VHDL package that
# holds it, ../sd_menu_stub.vhdl, which is checked in so that the simulation
# and Quartus builds do not need cc65. stub.nes is the stub's image as
# sd_menu streams it, for stub_test.sh. menu.nes is the menu, which goes on
# the card as MENU.NES. make sd_card.img makes a card image holding it (see
# sd_image.sh)

CA65 ?= ca65
LD65 ?= ld65
PYTHON ?= python3 -B

all: ../sd_menu_stub.vhdl menu.nes

%.o: %.s fat.inc
	$(CA65) $< -o $@ -l $*.lst

stub.bin: stub.o fat.o stub.cfg
	$(LD65) -C stub.cfg -o $@ -m stub.map stub.o fat.o

font.chr: font.py
	$(PYTHON) font.py $@

menu.o: font.chr

menu.nes: menu.o fat.o menu.cfg
	$(LD65) -C menu.cfg -o $@ -m menu.map menu.o fat.o

../sd_menu_stub.vhdl stub.nes &: stub.bin stub_rom.py
	$(PYTHON) stub_rom.py stub.bin ../sd_menu_stub.vhdl --nes stub.nes

sd_card.img: menu.nes sd_image.sh
	./sd_image.sh $@

clean:
	rm -f *.o *.lst stub.bin stub.map stub.nes font.chr menu.map menu.nes \
		sd_card.img sd_card.img.gz

.PHONY: all clean
