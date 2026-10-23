# Generates the test ROMs that check themselves, showing a green backdrop on a
# pass, for the regression tests in board/sim/ghdl/nes_tests.txt. The ROMs
# are generated rather than checked in so that they stay in step with the
# scripts. run_nes_tests.sh runs this before the tests.
#
# The ROMs checked by ear or against Mesen (apu_timers.py, the audio variants
# of mmc5_audio.py and vrc6.py) and the debugging variants (mmc5.py ines_dump,
# mmc5_split.py continue) are left out.

OUT ?= ../../board/sim/ghdl/generated_roms
# -B: no __pycache__ in the source tree, which would be owned by root when
# run in the docker container
PYTHON ?= python3 -B

FME7_VARIANTS := ines nes2
LATCH_CHR_RAM_VARIANTS := cprom unrom512 flash single four hv
MMC1_PRG_RAM_VARIANTS := sorom sxrom szrom ines
MMC5_VARIANTS := ines ekrom etrom ewrom
MMC5_AUDIO_VARIANTS := check
VRC4_VARIANTS := 21_ines_a 21_ines_c 21_1 21_2 22 23_ines_f 23_ines_e 23_1 \
                 23_2 23_3 25_ines_b 25_ines_d 25_1 25_2 25_3
VRC6_VARIANTS := 24 26 24_nes2

FME7_ROMS := $(FME7_VARIANTS:%=$(OUT)/fme7_%.nes)
LATCH_CHR_RAM_ROMS := $(LATCH_CHR_RAM_VARIANTS:%=$(OUT)/latch_chr_ram_%.nes)
MMC1_PRG_RAM_ROMS := $(MMC1_PRG_RAM_VARIANTS:%=$(OUT)/mmc1_prg_ram_%.nes)
MMC5_ROMS := $(MMC5_VARIANTS:%=$(OUT)/mmc5_%.nes)
MMC5_AUDIO_ROMS := $(MMC5_AUDIO_VARIANTS:%=$(OUT)/mmc5_audio_%.nes)
VRC4_ROMS := $(VRC4_VARIANTS:%=$(OUT)/vrc4_%.nes)
VRC6_ROMS := $(VRC6_VARIANTS:%=$(OUT)/vrc6_%.nes)

ROMS := $(FME7_ROMS) $(LATCH_CHR_RAM_ROMS) $(MMC1_PRG_RAM_ROMS) $(MMC5_ROMS) \
        $(MMC5_AUDIO_ROMS) $(VRC4_ROMS) $(VRC6_ROMS) $(OUT)/mmc5_split.nes

.PHONY: all clean
.DELETE_ON_ERROR:

all: $(ROMS)

# Static pattern rules, since mmc5_% would also match mmc5_split and
# mmc5_audio_%
$(FME7_ROMS): $(OUT)/fme7_%.nes: fme7.py | $(OUT)
	$(PYTHON) fme7.py $@ $*

$(LATCH_CHR_RAM_ROMS): $(OUT)/latch_chr_ram_%.nes: latch_chr_ram.py | $(OUT)
	$(PYTHON) latch_chr_ram.py $@ $*

$(MMC1_PRG_RAM_ROMS): $(OUT)/mmc1_prg_ram_%.nes: mmc1_prg_ram.py | $(OUT)
	$(PYTHON) mmc1_prg_ram.py $@ $*

$(MMC5_ROMS): $(OUT)/mmc5_%.nes: mmc5.py | $(OUT)
	$(PYTHON) mmc5.py $@ $*

$(MMC5_AUDIO_ROMS): $(OUT)/mmc5_audio_%.nes: mmc5_audio.py | $(OUT)
	$(PYTHON) mmc5_audio.py $@ $*

$(VRC4_ROMS): $(OUT)/vrc4_%.nes: vrc4.py | $(OUT)
	$(PYTHON) vrc4.py $@ $*

$(VRC6_ROMS): $(OUT)/vrc6_%.nes: vrc6.py | $(OUT)
	$(PYTHON) vrc6.py $@ $*

$(OUT)/mmc5_split.nes: mmc5_split.py mmc5.py | $(OUT)
	$(PYTHON) mmc5_split.py $@

$(OUT):
	mkdir -p $@

clean:
	rm -f $(ROMS)
