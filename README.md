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

* Games playable from embedded flash memory on the DE1 board
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

Mappers currently supported:
* 000
* 001
* 002
* 003
* 004

So very much a work in progress still. However my emphasis to date has been on
emulation accuracy of the CPU, PPU, and APU to make sure that's solid.

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
* Reading joystick input data from FCEUX .fm2 files

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
