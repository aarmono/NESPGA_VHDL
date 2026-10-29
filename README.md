# NESPGA - A Synthesizable NES on an FPGA

The goal of this project is/was to make a better, open source version of those
knock-off NES consoles that all use the same NES-on-a-chip using a low-cost, off
the shelf FPGA board. There is no co-processor design that tries to replicate
various functions traditionally found in emulators. Someone could probably 
take my design and add that to it, but that is outside the scope of this
project. This project simply plays games the way those retro consoles do.

NESPGA currently targets the (now obsolete) DE1 board from Terasic. This board
features a Cyclone II with 20K logic elements, and the design fits comfortably
in that. The NES poses no difficulty for modern FPGA hardware: the main
constraint is memory which more modern FPGAs have much more of.
The current status is:

* Games playable from NES roms flashed onto an SD card using the on-board SD
  card slot
* Video using the on-board VGA output (color resolution is 4-bit per channel
  due to the way the VGA hardware is designed, but this does not appear to
  matter significantly)
* Audio from the line out on the board
* Joystick control using a PS2 keyboard (key map is hardcoded)

Joystick keymap
* wsad for directional buttons
* j = B Button
* k = A Button
* u = Select
* i = Start
* Escape = Reset

KEY0 on the board is also the reset button.

Mappers currently supported:

| Family | Mappers |
|---|---|
| Discrete latch boards (NROM, UxROM, CNROM, AxROM, multicarts, ...) | 0, 2, 3, 7, 11, 13, 30, 34, 58, 61, 62, 66, 70, 71, 72, 77, 78, 79, 86, 87, 89, 92, 93, 94, 97, 101, 140, 146, 152, 180, 184, 185, 200, 201, 202, 203, 212, 213, 214, 218, 225, 226, 227, 228, 231, 232, 242, 255 |
| MMC1 | 1, 105, 155 |
| MMC2 / MMC4 | 9, 10 |
| MMC3 / MMC6 / Namco 108 (and MMC3 multicarts) | 4, 37, 44, 45, 47, 49, 52, 76, 88, 95, 118, 119, 154, 206 |
| MMC5 (including audio) | 5 |
| Sunsoft FME-7 / 5B (including audio) | 69 |
| Konami VRC2 / VRC4 | 21, 22, 23, 25 |
| Konami VRC6 (including audio) | 24, 26 |
| Konami VRC7 (including audio) | 85 |
| Tengen RAMBO-1 | 64, 158 |
| Namco 163 (including audio) / 175 / 340 | 19, 210 |
| Action 53 | 28 |
| Bandai FCG-1/2 / LZ93D50 (with serial EEPROMs; no Datach barcode reader) | 16, 153, 157, 159 |
| Jaleco SS 88006 (no ADPCM audio) | 18 |
| Taito TC0190 / TC0690 / X1-005 / X1-017 | 33, 48, 80, 82, 207, 552 |
| Sunsoft-3 / Sunsoft-4 (including the Dual Cartridge System) / Konami VRC3 | 67, 68, 73 |
| Irem G-101 / H3001 / Konami VRC1 | 32, 65, 75 |
| NSF subset | 31 |

Bus conflicts on discrete boards, flash saving on mapper 30 and the ADPCM
audio of the Jaleco boards (72, 86, 92) are not emulated.

The design is synthesized using Quartus 13.0.1 Web Edition, the last version
to support the Cyclone II.

## How This Differs from MiSTer

The simple answer is that MiSTer didn't exist when I started this project, and
my goals were less ambitious than MiSTer's. If it had existed, perhaps this
project wouldn't have existed at all. Regardless, there are a couple significant
differences.

The primary difference is the design is written in a very high-level style. I am
a programmer by profession, so I wrote the design like I would if it were a
program. Most of the logic is written in VHDL functions which are then used
to update registers and output signals. My hope is that this makes the code
more approachable and also easier to understand. Since there was a 10-year
gap where I wasn't working or thinking about the project at all, I consider
this goal met.

The second difference is I spent time getting automated test-benches set up
and running using a VHDL simulator. I find simulators invaluable when
interfacing with hardware, so I wanted to make sure I had one that worked well.
The simulator supports the following:

* Loading .NES files into simulated flash memory
* Dumping audio data to uncompressed .au files
* Dumping video frames to .bmp files
* Reading joystick input data from FCEUX .fm2 files, including soft reset

Scripts are included which can take the audio and video files and use ffmpeg to
generate video files from the data
([example](https://www.youtube.com/watch?v=CVuoEuP-UWM)). This is mostly a
gimmick since the simulation is so slow (that video took 2 days to render) but
may be useful in limited situations.

There are also scripts which will automatically execute test ROMs and compare
the output to known good values to minimize regression issues. This test suite
runs using the open source GHDL simulator and runs within the official GHDL
Docker image. Multiple tests can be run in parallel since GHDL is
single-threaded, to improve performance.
