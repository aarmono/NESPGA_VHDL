# Generates the test ROMs that check themselves, showing a green backdrop on a
# pass, for the regression tests in board/sim/ghdl/nes_tests.txt. The ROMs
# are generated rather than checked in so that they stay in step with the
# scripts. run_nes_tests.sh runs this before the tests.
#
# The ROMs checked by ear or against Mesen (apu_timers.py, the audio variants
# of mmc5_audio.py, n163.py and vrc6.py) and the debugging variants (mmc5.py
# ines_dump, mmc5_split.py continue, rambo1.py dump/continue) are left out.

OUT ?= ../../board/sim/ghdl/generated_roms
NES_TEST_ROMS := ../../nes-test-roms
# -B: no __pycache__ in the source tree, which would be owned by root when
# run in the docker container
PYTHON ?= python3 -B

FME7_VARIANTS := ines nes2
LATCH_VARIANTS := nrom_128 nrom_256_v uxrom uorom cnrom axrom colordreams \
                  bnrom_ines bnrom_nes2 nina001_ines nina001_nes2 gxrom
LATCH_CHR_RAM_VARIANTS := cprom unrom512 flash single four hv
LATCH_ADDR_VARIANTS := 228_a52 228_small
LATCH_BOARDS_VARIANTS := 70 70_1scr 152 71 71_1 78_1 78_3 78_ines 79 146 87 \
                         89 93 94 97 101 140 180 184 185_4 185_5 185_6 185_7 \
                         185_ines 232 232_1 58 61 61_1 61_ram 62 200 200_1 \
                         201 202 203 212 213 214 225 255 226 227 227_2 \
                         227_rpg 242 242_rpg 231
MMC1_VARIANTS := sxrom surom serom 155 105
MMC1_PRG_RAM_VARIANTS := sorom sxrom szrom ines
MMC2_VARIANTS := mmc2 mmc4
MMC3_VARIANTS := mmc3 mmc3_big qj txsrom tqrom mmc6_nes2 mmc6_ines 206 88 76 \
                 95 154
MMC5_VARIANTS := ines ekrom etrom ewrom
MMC5_AUDIO_VARIANTS := check
N163_VARIANTS := 163_ines 163_nes2 175 340 detect_19 detect_210
RAMBO1_VARIANTS := 64 158
VRC4_VARIANTS := 21_ines_a 21_ines_c 21_1 21_2 22 23_ines_f 23_ines_e 23_1 \
                 23_2 23_3 25_ines_b 25_ines_d 25_1 25_2 25_3
VRC6_VARIANTS := 24 26 24_nes2

FME7_ROMS := $(FME7_VARIANTS:%=$(OUT)/fme7_%.nes)
LATCH_ROMS := $(LATCH_VARIANTS:%=$(OUT)/latch_%.nes)
LATCH_CHR_RAM_ROMS := $(LATCH_CHR_RAM_VARIANTS:%=$(OUT)/latch_chr_ram_%.nes)
LATCH_ADDR_ROMS := $(LATCH_ADDR_VARIANTS:%=$(OUT)/latch_addr_%.nes)
LATCH_BOARDS_ROMS := $(LATCH_BOARDS_VARIANTS:%=$(OUT)/latch_boards_%.nes)
MMC1_ROMS := $(MMC1_VARIANTS:%=$(OUT)/mmc1_%.nes)
MMC1_PRG_RAM_ROMS := $(MMC1_PRG_RAM_VARIANTS:%=$(OUT)/mmc1_prg_ram_%.nes)
MMC2_ROMS := $(MMC2_VARIANTS:%=$(OUT)/mmc2_%.nes)
MMC3_ROMS := $(MMC3_VARIANTS:%=$(OUT)/mmc3_%.nes)
MMC5_ROMS := $(MMC5_VARIANTS:%=$(OUT)/mmc5_%.nes)
MMC5_AUDIO_ROMS := $(MMC5_AUDIO_VARIANTS:%=$(OUT)/mmc5_audio_%.nes)
N163_ROMS := $(N163_VARIANTS:%=$(OUT)/n163_%.nes)
RAMBO1_ROMS := $(RAMBO1_VARIANTS:%=$(OUT)/rambo1_%.nes)
VRC4_ROMS := $(VRC4_VARIANTS:%=$(OUT)/vrc4_%.nes)
VRC6_ROMS := $(VRC6_VARIANTS:%=$(OUT)/vrc6_%.nes)

# Test ROMs of nes-test-roms copied with an NES 2.0 header, for boards an
# iNES header cannot select
NES2_ROMS := $(OUT)/nes2_mmc3_alt.nes $(OUT)/nes2_mmc3_rev_a.nes \
             $(OUT)/nes2_mmc1_a12.nes

ROMS := $(FME7_ROMS) $(LATCH_ROMS) $(LATCH_CHR_RAM_ROMS) $(LATCH_ADDR_ROMS) \
        $(LATCH_BOARDS_ROMS) \
        $(MMC1_ROMS) $(MMC1_PRG_RAM_ROMS) $(MMC2_ROMS) $(MMC3_ROMS) \
        $(MMC5_ROMS) $(MMC5_AUDIO_ROMS) $(N163_ROMS) $(RAMBO1_ROMS) \
        $(VRC4_ROMS) $(VRC6_ROMS) \
        $(OUT)/mmc5_split.nes $(NES2_ROMS)

.PHONY: all clean
.DELETE_ON_ERROR:

all: $(ROMS)

# Static pattern rules, since mmc5_% would also match mmc5_split and
# mmc5_audio_%, and likewise latch_% and mmc1_%
$(FME7_ROMS): $(OUT)/fme7_%.nes: fme7.py | $(OUT)
	$(PYTHON) fme7.py $@ $*

$(LATCH_ROMS): $(OUT)/latch_%.nes: latch.py | $(OUT)
	$(PYTHON) latch.py $@ $*

$(LATCH_CHR_RAM_ROMS): $(OUT)/latch_chr_ram_%.nes: latch_chr_ram.py | $(OUT)
	$(PYTHON) latch_chr_ram.py $@ $*

$(LATCH_ADDR_ROMS): $(OUT)/latch_addr_%.nes: latch_addr.py | $(OUT)
	$(PYTHON) latch_addr.py $@ $*

$(LATCH_BOARDS_ROMS): $(OUT)/latch_boards_%.nes: latch_boards.py | $(OUT)
	$(PYTHON) latch_boards.py $@ $*

$(MMC1_ROMS): $(OUT)/mmc1_%.nes: mmc1.py | $(OUT)
	$(PYTHON) mmc1.py $@ $*

$(MMC1_PRG_RAM_ROMS): $(OUT)/mmc1_prg_ram_%.nes: mmc1_prg_ram.py | $(OUT)
	$(PYTHON) mmc1_prg_ram.py $@ $*

$(MMC2_ROMS): $(OUT)/mmc2_%.nes: mmc2.py | $(OUT)
	$(PYTHON) mmc2.py $@ $*

$(MMC3_ROMS): $(OUT)/mmc3_%.nes: mmc3.py | $(OUT)
	$(PYTHON) mmc3.py $@ $*

$(MMC5_ROMS): $(OUT)/mmc5_%.nes: mmc5.py | $(OUT)
	$(PYTHON) mmc5.py $@ $*

$(MMC5_AUDIO_ROMS): $(OUT)/mmc5_audio_%.nes: mmc5_audio.py | $(OUT)
	$(PYTHON) mmc5_audio.py $@ $*

$(N163_ROMS): $(OUT)/n163_%.nes: n163.py | $(OUT)
	$(PYTHON) n163.py $@ $*

$(RAMBO1_ROMS): $(OUT)/rambo1_%.nes: rambo1.py | $(OUT)
	$(PYTHON) rambo1.py $@ $*

$(VRC4_ROMS): $(OUT)/vrc4_%.nes: vrc4.py | $(OUT)
	$(PYTHON) vrc4.py $@ $*

$(VRC6_ROMS): $(OUT)/vrc6_%.nes: vrc6.py | $(OUT)
	$(PYTHON) vrc6.py $@ $*

$(OUT)/mmc5_split.nes: mmc5_split.py mmc5.py | $(OUT)
	$(PYTHON) mmc5_split.py $@

# NEC MMC3
$(OUT)/nes2_mmc3_alt.nes: $(NES_TEST_ROMS)/mmc3_test_2/rom_singles/6-MMC3_alt.nes \
                          nes2_header.py | $(OUT)
	$(PYTHON) nes2_header.py $< $@ submapper=4 prg_ram=8192

$(OUT)/nes2_mmc3_rev_a.nes: $(NES_TEST_ROMS)/mmc3_irq_tests/5.MMC3_rev_A.nes \
                            nes2_header.py | $(OUT)
	$(PYTHON) nes2_header.py $< $@ submapper=4 prg_ram=8192 chr_ram=8192

# SNROM
$(OUT)/nes2_mmc1_a12.nes: $(NES_TEST_ROMS)/MMC1_A12/mmc1_a12.nes \
                          nes2_header.py | $(OUT)
	$(PYTHON) nes2_header.py $< $@ prg_ram=8192 chr_ram=8192

$(OUT):
	mkdir -p $@

clean:
	rm -f $(ROMS)
