# Makefile automatically generated by ghdl
# Version: GHDL 3.0.0-dev (v2.0.0-859-g5cbfa82eb) [Dunoon edition] - llvm code generator
# Command used to generate this makefile:
# ghdl gen-makefile --std=08 nes_bench

GHDL=ghdl
GHDLFLAGS= --std=08 -O3

# Default target
all: nes_bench

# Elaboration target
nes_bench: /usr/local/lib/ghdl/std/v08/textio.o /usr/local/lib/ghdl/std/v08/textio-body.o /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/std_logic_1164-body.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o /usr/local/lib/ghdl/ieee/v08/numeric_std-body.o utilities.o nes_types.o ram_bus_types.o sram_bus_types.o chr_bus_types.o cpu_bus_types.o file_bus_types.o oam_bus_types.o sec_oam_bus_types.o palette_bus_types.o soc.o apu_bus_types.o nes_audio_mixer.o simulation.o nes_bench.o perhipherals.o joy_bus_types.o ppu_bus_types.o prg_bus_types.o nes_core.o mapper_types.o lib_mapper_000.o lib_mapper_002.o lib_nsf_rom.o lib_mapper_220.o lib_mapper.o lib_nes_mmap.o lib_nes.o nes_soc.o nes_soc_ocram.o binary_io.o bmp_file.o ppu_video_record.o au_file.o apu_audio_record.o fm2_file.o fm2_joystick.o file_memory.o clock.o clk_en.o lib_cpu_types.o lib_cpu_decode_defs.o lib_cpu_decode.o lib_cpu_exec.o lib_cpu.o cpu.o lib_apu_frame_seq.o lib_apu_length.o lib_apu_envelope.o lib_apu_square.o lib_apu_triangle.o lib_apu_noise.o lib_apu_dmc.o lib_apu.o apu.o joystick_io.o lib_ppu.o ppu.o oam_dma.o syncram_sp.o
	$(GHDL) -e $(GHDLFLAGS) $@

# Run target
run: nes_bench
	$(GHDL) -r nes_bench $(GHDLRUNFLAGS)

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
ram_bus_types.o: ../../../bus/ram_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
sram_bus_types.o: ../../../bus/sram_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
chr_bus_types.o: ../../../bus/chr_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
cpu_bus_types.o: ../../../bus/cpu_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
file_bus_types.o: ../../../bus/file_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
oam_bus_types.o: ../../../bus/oam_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
sec_oam_bus_types.o: ../../../bus/sec_oam_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
palette_bus_types.o: ../../../bus/palette_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
soc.o: ../../../soc/soc.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
apu_bus_types.o: ../../../bus/apu_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
nes_audio_mixer.o: ../../../core/nes_audio_mixer.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
simulation.o: ../../../simulation/simulation.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
nes_bench.o: ../../../board/sim/nes_bench.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
perhipherals.o: ../../../perhiperals/perhipherals.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
joy_bus_types.o: ../../../bus/joy_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
ppu_bus_types.o: ../../../bus/ppu_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
prg_bus_types.o: ../../../bus/prg_bus_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
nes_core.o: ../../../core/nes_core.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
mapper_types.o: ../../../core/mappers/mapper_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_mapper_000.o: ../../../core/mappers/000/lib_mapper_000.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_mapper_002.o: ../../../core/mappers/002/lib_mapper_002.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_nsf_rom.o: ../../../core/mappers/220/lib_nsf_rom.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_mapper_220.o: ../../../core/mappers/220/lib_mapper_220.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_mapper.o: ../../../core/mappers/lib_mapper.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_nes_mmap.o: ../../../core/lib_nes_mmap.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_nes.o: ../../../soc/nes/lib_nes.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
nes_soc.o: ../../../soc/nes/nes_soc.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
nes_soc_ocram.o: ../../../soc/nes/nes_soc_ocram.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
binary_io.o: ../../../simulation/binary_io.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
bmp_file.o: ../../../simulation/bmp_file.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
ppu_video_record.o: ../../../simulation/ppu_video_record/ppu_video_record.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
au_file.o: ../../../simulation/au_file.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
apu_audio_record.o: ../../../simulation/apu_audio_record/apu_audio_record.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
fm2_file.o: ../../../simulation/fm2_file.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
fm2_joystick.o: ../../../simulation/fm2_joystick/fm2_joystick.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
file_memory.o: ../../../simulation/file_memory/file_memory.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
clock.o: ../../../simulation/clock/clock.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
clk_en.o: ../../../core/clk_en/clk_en.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_cpu_types.o: ../../../core/cpu/lib_cpu_types.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_cpu_decode_defs.o: ../../../core/cpu/lib_cpu_decode_defs.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_cpu_decode.o: ../../../core/cpu/lib_cpu_decode.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_cpu_exec.o: ../../../core/cpu/lib_cpu_exec.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_cpu.o: ../../../core/cpu/lib_cpu.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
cpu.o: ../../../core/cpu/cpu.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_apu_frame_seq.o: ../../../core/apu/lib_apu_frame_seq.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_apu_length.o: ../../../core/apu/lib_apu_length.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_apu_envelope.o: ../../../core/apu/lib_apu_envelope.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_apu_square.o: ../../../core/apu/lib_apu_square.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_apu_triangle.o: ../../../core/apu/lib_apu_triangle.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_apu_noise.o: ../../../core/apu/lib_apu_noise.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_apu_dmc.o: ../../../core/apu/lib_apu_dmc.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_apu.o: ../../../core/apu/lib_apu.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
apu.o: ../../../core/apu/apu.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
joystick_io.o: ../../../core/joystick_io/joystick_io.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
lib_ppu.o: ../../../core/ppu/lib_ppu.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
ppu.o: ../../../core/ppu/ppu.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
oam_dma.o: ../../../core/oam_dma/oam_dma.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
syncram_sp.o: ../../../perhiperals/syncram_sp/syncram_sp.vhdl
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
ram_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
sram_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
chr_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
cpu_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
file_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
oam_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
sec_oam_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
palette_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
soc.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o cpu_bus_types.o ram_bus_types.o sram_bus_types.o oam_bus_types.o sec_oam_bus_types.o palette_bus_types.o file_bus_types.o chr_bus_types.o nes_types.o
apu_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
nes_audio_mixer.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o nes_types.o
simulation.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o apu_bus_types.o file_bus_types.o nes_types.o nes_audio_mixer.o
nes_bench.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/std_logic_1164-body.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o /usr/local/lib/ghdl/ieee/v08/numeric_std-body.o nes_types.o ram_bus_types.o sram_bus_types.o chr_bus_types.o cpu_bus_types.o file_bus_types.o oam_bus_types.o sec_oam_bus_types.o palette_bus_types.o utilities.o soc.o simulation.o
perhipherals.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
joy_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
ppu_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
prg_bus_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
nes_core.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o cpu_bus_types.o apu_bus_types.o ram_bus_types.o sram_bus_types.o ppu_bus_types.o prg_bus_types.o chr_bus_types.o oam_bus_types.o sec_oam_bus_types.o palette_bus_types.o joy_bus_types.o nes_types.o utilities.o
mapper_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o utilities.o nes_types.o cpu_bus_types.o sram_bus_types.o file_bus_types.o apu_bus_types.o ram_bus_types.o ppu_bus_types.o chr_bus_types.o palette_bus_types.o joy_bus_types.o
lib_mapper_000.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o cpu_bus_types.o apu_bus_types.o ram_bus_types.o sram_bus_types.o file_bus_types.o chr_bus_types.o nes_types.o utilities.o mapper_types.o
lib_mapper_002.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o cpu_bus_types.o apu_bus_types.o ram_bus_types.o sram_bus_types.o file_bus_types.o chr_bus_types.o nes_types.o utilities.o mapper_types.o
lib_nsf_rom.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o
lib_mapper_220.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o cpu_bus_types.o apu_bus_types.o ram_bus_types.o sram_bus_types.o file_bus_types.o nes_types.o lib_nsf_rom.o utilities.o mapper_types.o
lib_mapper.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o utilities.o nes_types.o chr_bus_types.o sram_bus_types.o file_bus_types.o mapper_types.o lib_mapper_000.o lib_mapper_002.o lib_mapper_220.o
lib_nes_mmap.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o cpu_bus_types.o apu_bus_types.o ram_bus_types.o sram_bus_types.o ppu_bus_types.o file_bus_types.o chr_bus_types.o nes_types.o utilities.o mapper_types.o lib_mapper.o
lib_nes.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o cpu_bus_types.o apu_bus_types.o ram_bus_types.o sram_bus_types.o chr_bus_types.o oam_bus_types.o sec_oam_bus_types.o prg_bus_types.o palette_bus_types.o file_bus_types.o nes_types.o nes_audio_mixer.o utilities.o mapper_types.o lib_mapper.o lib_nes_mmap.o
nes_soc.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o utilities.o cpu_bus_types.o apu_bus_types.o joy_bus_types.o ram_bus_types.o sram_bus_types.o file_bus_types.o chr_bus_types.o oam_bus_types.o sec_oam_bus_types.o ppu_bus_types.o palette_bus_types.o nes_types.o nes_core.o lib_nes.o
nes_soc_ocram.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o nes_types.o ram_bus_types.o sram_bus_types.o chr_bus_types.o cpu_bus_types.o file_bus_types.o oam_bus_types.o sec_oam_bus_types.o palette_bus_types.o utilities.o perhipherals.o nes_soc.o
binary_io.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o utilities.o
bmp_file.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o utilities.o binary_io.o
ppu_video_record.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o nes_types.o binary_io.o bmp_file.o /usr/local/lib/ghdl/std/v08/textio.o
au_file.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o binary_io.o
apu_audio_record.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o nes_types.o binary_io.o au_file.o
fm2_file.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o /usr/local/lib/ghdl/std/v08/textio.o
fm2_joystick.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o /usr/local/lib/ghdl/std/v08/textio.o fm2_file.o
file_memory.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o utilities.o binary_io.o nes_types.o file_bus_types.o
clock.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o
clk_en.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o utilities.o
lib_cpu_types.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o cpu_bus_types.o nes_types.o utilities.o
lib_cpu_decode_defs.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o cpu_bus_types.o nes_types.o utilities.o lib_cpu_types.o
lib_cpu_decode.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o cpu_bus_types.o nes_types.o utilities.o lib_cpu_types.o lib_cpu_decode_defs.o
lib_cpu_exec.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o cpu_bus_types.o nes_types.o utilities.o lib_cpu_types.o
lib_cpu.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o cpu_bus_types.o nes_types.o utilities.o lib_cpu_types.o lib_cpu_decode.o lib_cpu_exec.o
cpu.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o cpu_bus_types.o nes_types.o utilities.o lib_cpu.o
lib_apu_frame_seq.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o nes_types.o utilities.o
lib_apu_length.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o nes_types.o utilities.o
lib_apu_envelope.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o nes_types.o utilities.o
lib_apu_square.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o nes_types.o utilities.o lib_apu_length.o lib_apu_envelope.o
lib_apu_triangle.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o nes_types.o utilities.o lib_apu_length.o
lib_apu_noise.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o nes_types.o utilities.o lib_apu_length.o lib_apu_envelope.o
lib_apu_dmc.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o cpu_bus_types.o nes_types.o utilities.o
lib_apu.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o nes_types.o apu_bus_types.o cpu_bus_types.o utilities.o lib_apu_frame_seq.o lib_apu_square.o lib_apu_triangle.o lib_apu_noise.o lib_apu_dmc.o
apu.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o nes_types.o lib_apu.o apu_bus_types.o cpu_bus_types.o utilities.o
joystick_io.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o joy_bus_types.o nes_types.o utilities.o
lib_ppu.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o nes_types.o utilities.o chr_bus_types.o ppu_bus_types.o oam_bus_types.o sec_oam_bus_types.o palette_bus_types.o
ppu.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o lib_ppu.o ppu_bus_types.o chr_bus_types.o oam_bus_types.o sec_oam_bus_types.o palette_bus_types.o nes_types.o utilities.o
oam_dma.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o cpu_bus_types.o nes_types.o utilities.o
syncram_sp.o:  /usr/local/lib/ghdl/ieee/v08/std_logic_1164.o /usr/local/lib/ghdl/ieee/v08/numeric_std.o
