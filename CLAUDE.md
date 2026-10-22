Running run_nes_tests.sh takes on the order of 2-3 hours on this machine. Do not run it if you are trying to quickly test a fix, preferring instead to run individual tests around the area being changed.

nes_de1_bench is much (about 5.5x) slower than nes_bench since it simulates the Terasic DE1 board hardware. Most of its time is in the VGA generator, the WM8731 interface and ghdl's signal/event handling, not the NES core. It does not need to be run unless debugging/changing entities related to board interop (perhiperals/ or board/de1/ directories), and even then it is preferable to test entities individually. nes_bench is optimized to run within ghdl, which is where simulation is primarily run. nes_de1_bench frame hashes differ from those of nes_bench as the former are of VGA frames. Audio hashes also differ as the audio is delayed by about a frame.

Timing analysis has shown that arithmetic and comparison operators using numeric_std is very slow in ghdl compared to using the VHDL built-in integer type. In hot code paths prefer the latter where doing so keeps the code clean. There are functions in utilities.vhd that approximate some of the nicities of using numeric_std

Synthesizable code for this project is synthesized using Quartus Web Edition version 13.0.1 (circa 2013). Its support for VHDL 08 is limited. Certain valid synthesizable 08 features may be accepted by ghdl but not synthesize simply due to language compatability issues. Quartus is installed in a docker container on this machine.

ghdl runs within a docker container using the run_ghdl.sh script, however the executables built by ghdl within the docker container (nes_bench et al) can run within the host OS if needed as the docker container has limited functionality (eg. generating nes_bench through the docker container but running nes_bench directly or through valgrond on the host OS). run_nes_bench.sh and run_nes_tests.sh cannot be run directly on the host since they run make

the docker container runs as root, so files generated from within the docker container will have root ownership and may need to be deleted from within the docker container using run_ghdl.sh

mesen-agent is installed on this machine. use the mesen-agent skill to reference what mesen does if mesen is passing a test this project does not.

Prefer pure combinational logic to go into functions when feasible. if combinational logic is only assigning into regsitered values, prefer calling that function from within a clocked process instead of using the two-process method where that function is called from within a combinational process.

Direct entity instantiations are OK within a subsystem (eg. cartridge can reference mapper entities directly), but prefer component declarations/instantiations across subsystems (eg. soc should use cartridge component declaration which the cartridge subsystem defines).