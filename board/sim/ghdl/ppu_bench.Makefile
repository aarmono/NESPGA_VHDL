# Makefile automatically generated by ghdl
# Version: GHDL 3.0.0-dev (v2.0.0-859-g5cbfa82eb) [Dunoon edition] - llvm code generator
# Command used to generate this makefile:
# ghdl gen-makefile --std=08 ppu_bench

GHDL=ghdl
GHDLFLAGS= --std=08 -O3

# Default target
all: ppu_bench

# Elaboration target
ppu_bench: /usr/local/lib/ghdl/std/v08/textio.o /usr/local/lib/ghdl/std/v08/textio-body.o /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/std_logic_1164-body.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o /usr/local/lib/ghdl/ieee/v08/numeric_std-body.o utilities.o nes_types.o cpu_bus_types.o apu_bus_types.o ram_bus_types.o sram_bus_types.o ppu_bus_types.o prg_bus_types.o chr_bus_types.o oam_bus_types.o sec_oam_bus_types.o palette_bus_types.o joy_bus_types.o nes_core.o file_bus_types.o nes_audio_mixer.o simulation.o /usr/local/lib/ghdl/std/v08/env.o /usr/local/lib/ghdl/std/v08/env-body.o ppu_bench.o binary_io.o bmp_file.o ppu_video_record.o file_memory.o lib_ppu.o ppu.o
	$(GHDL) -e $(GHDLFLAGS) $@

# Run target
run: ppu_bench
	$(GHDL) -r ppu_bench $(GHDLRUNFLAGS)

# Targets to analyze files
/usr/local/lib/ghdl/std/v08/textio.o: /usr/local/lib/ghdl/std/v08/../../src/std/v08/textio.vhdl
	@echo "This file was not locally built ($<)"
	exit 1
/usr/local/lib/ghdl/std/v08/textio-body.o: /usr/local/lib/ghdl/std/v08/../../src/std/v08/textio-body.vhdl
	@echo "This file was not locally built ($<)"
	exit 1
/usr/local/lib/ghdl/ieee/v08/std_logic_1164.o: /usr/local/lib/ghdl/ieee/v08/../../src/ieee2008/std_logic_1164.vhdl
	@echo "This file was not locally built ($<)"
	exit 1
/usr/local/lib/ghdl/ieee/v08/std_logic_1164-body.o: /usr/local/lib/ghdl/ieee/v08/../../src/ieee2008/std_logic_1164-body.vhdl
	@echo "This file was not locally built ($<)"
	exit 1
/usr/local/lib/ghdl/ieee/v08/numeric_std.o: /usr/local/lib/ghdl/ieee/v08/../../src/ieee2008/numeric_std.vhdl
	@echo "This file was not locally built ($<)"
	exit 1
/usr/local/lib/ghdl/ieee/v08/numeric_std-body.o: /usr/local/lib/ghdl/ieee/v08/../../src/ieee2008/numeric_std-body.vhdl
	@echo "This file was not locally built ($<)"
	exit 1
utilities.o: ../../../common/utilities.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
nes_types.o: ../../../core/nes_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
cpu_bus_types.o: ../../../bus/cpu_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
apu_bus_types.o: ../../../bus/apu_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
ram_bus_types.o: ../../../bus/ram_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
sram_bus_types.o: ../../../bus/sram_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
ppu_bus_types.o: ../../../bus/ppu_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
prg_bus_types.o: ../../../bus/prg_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
chr_bus_types.o: ../../../bus/chr_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
oam_bus_types.o: ../../../bus/oam_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
sec_oam_bus_types.o: ../../../bus/sec_oam_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
palette_bus_types.o: ../../../bus/palette_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
joy_bus_types.o: ../../../bus/joy_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
nes_core.o: ../../../core/nes_core.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
file_bus_types.o: ../../../bus/file_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
nes_audio_mixer.o: ../../../core/nes_audio_mixer.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
simulation.o: ../../../simulation/simulation.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
/usr/local/lib/ghdl/std/v08/env.o: /usr/local/lib/ghdl/std/v08/../../src/std/env.vhdl
	@echo "This file was not locally built ($<)"
	exit 1
/usr/local/lib/ghdl/std/v08/env-body.o: /usr/local/lib/ghdl/std/v08/../../src/std/env-body.vhdl
	@echo "This file was not locally built ($<)"
	exit 1
ppu_bench.o: ../../../core/ppu/ppu_bench.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
binary_io.o: ../../../simulation/binary_io.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
bmp_file.o: ../../../simulation/bmp_file.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
ppu_video_record.o: ../../../simulation/ppu_video_record/ppu_video_record.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
file_memory.o: ../../../simulation/file_memory/file_memory.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_ppu.o: ../../../core/ppu/lib_ppu.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
ppu.o: ../../../core/ppu/ppu.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<

# Files dependences
/usr/local/lib/ghdl/std/v08/textio.o: 
/usr/local/lib/ghdl/std/v08/textio-body.o:  /usr/local/lib/ghdl/std/v08/textio.o
/usr/local/lib/ghdl/ieee/v08/std_logic_1164.o:  /usr/local/lib/ghdl/std/v08/textio.o /usr/local/lib/ghdl/std/v08/textio-body.o
/usr/local/lib/ghdl/ieee/v08/std_logic_1164-body.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o
/usr/local/lib/ghdl/ieee/v08/numeric_std.o:  /usr/local/lib/ghdl/std/v08/textio.o /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o
/usr/local/lib/ghdl/ieee/v08/numeric_std-body.o:  /usr/local/lib/ghdl/ieee/v08/numeric_std.o
utilities.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
nes_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o utilities.o
cpu_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
apu_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
ram_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
sram_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
ppu_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
prg_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
chr_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
oam_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
sec_oam_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
palette_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
joy_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
nes_core.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o cpu_bus_types.o apu_bus_types.o ram_bus_types.o sram_bus_types.o ppu_bus_types.o prg_bus_types.o chr_bus_types.o oam_bus_types.o sec_oam_bus_types.o palette_bus_types.o joy_bus_types.o nes_types.o utilities.o
file_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
nes_audio_mixer.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o nes_types.o
simulation.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o apu_bus_types.o file_bus_types.o nes_types.o nes_audio_mixer.o
/usr/local/lib/ghdl/std/v08/env.o: 
/usr/local/lib/ghdl/std/v08/env-body.o:  /usr/local/lib/ghdl/std/v08/env.o
ppu_bench.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/std_logic_1164-body.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o /usr/local/lib/ghdl/ieee/v08/numeric_std-body.o utilities.o nes_types.o nes_core.o chr_bus_types.o oam_bus_types.o sec_oam_bus_types.o palette_bus_types.o file_bus_types.o ppu_bus_types.o simulation.o /usr/local/lib/ghdl/std/v08/env.o /usr/local/lib/ghdl/std/v08/env-body.o
binary_io.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o utilities.o
bmp_file.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o utilities.o binary_io.o
ppu_video_record.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o nes_types.o binary_io.o bmp_file.o /usr/local/lib/ghdl/std/v08/textio.o
file_memory.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o utilities.o binary_io.o nes_types.o file_bus_types.o
lib_ppu.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o nes_types.o utilities.o chr_bus_types.o ppu_bus_types.o oam_bus_types.o sec_oam_bus_types.o palette_bus_types.o
ppu.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o lib_ppu.o ppu_bus_types.o chr_bus_types.o oam_bus_types.o sec_oam_bus_types.o palette_bus_types.o nes_types.o utilities.o
