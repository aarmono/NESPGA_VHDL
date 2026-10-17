## Timing constraints for the DE1 NES top level (nes_top)
##
## DEVICE  "EP2C20F484C7"

set_time_format -unit ns -decimal_places 3


#**************************************************************
# Clocks
#**************************************************************

create_clock -name {CLOCK_50} -period 20.000 [get_ports {CLOCK_50}]
create_clock -name {CLOCK_27} -period 37.037 [get_ports {CLOCK_27[0]}]

# Let Quartus derive the PLL outputs from the PLL settings so that they do
# not go stale when a PLL is regenerated. The fitter picks the closest
# ratios the PLLs can produce:
#   aud_clock_gen c0: 50 * 7/19 = 18.42 MHz audio clock (CLOCK_AUD)
#   aud_clock_gen c1: 50 MHz, shifted -2.143 ns (CLOCK_WE)
#   vga_clock_gen c0: 27 * 14/15 = 25.2 MHz VGA pixel clock (CLOCK_VGA)
derive_pll_clocks

set clk_aud {aud_clock_gen|altpll_component|pll|clk[0]}
set clk_we  {aud_clock_gen|altpll_component|pll|clk[1]}
set clk_vga {vga_clock_gen|altpll_component|pll|clk[0]}

# CLOCK_WE drives DRAM_CLK directly
create_generated_clock -name {sdram_clk} \
    -source [get_pins $clk_we] \
    [get_ports {DRAM_CLK}]

# ppu_video_ram_mux gates CLOCK_WE onto SRAM_WE_N during writes, so the
# write strobe is low while CLOCK_WE is low
create_generated_clock -name {sram_we_clk} \
    -source [get_pins $clk_we] \
    [get_ports {SRAM_WE_N}]

derive_clock_uncertainty


#**************************************************************
# Clock Groups
#**************************************************************

# The audio clock comes from the same PLL as CLOCK_WE, but its frequency is
# not a simple ratio of 50 MHz and the design treats it as asynchronous
set_clock_groups -asynchronous \
    -group [get_clocks [list {CLOCK_50} $clk_we {sdram_clk} {sram_we_clk}]] \
    -group [get_clocks $clk_aud] \
    -group [get_clocks [list {CLOCK_27} $clk_vga]]


#**************************************************************
# SDRAM
#**************************************************************

# Board traces are assumed matched, so only the SDRAM's own timing is
# accounted for. Values are for a -7 speed grade part at CAS latency 2:
#   tAC 6.0 (access from clock), tOH 2.5 (output hold)
#   tSU 2.0 (input setup), tH 1.0 (input hold)
set sdram_outputs [get_ports {DRAM_ADDR[*] DRAM_BA_0 DRAM_BA_1 DRAM_CS_N \
                              DRAM_RAS_N DRAM_CAS_N DRAM_WE_N DRAM_CKE \
                              DRAM_LDQM DRAM_UDQM DRAM_DQ[*]}]

set_output_delay -clock {sdram_clk} -max  2.0 $sdram_outputs
set_output_delay -clock {sdram_clk} -min -1.0 $sdram_outputs

set_input_delay -clock {sdram_clk} -max 6.0 [get_ports {DRAM_DQ[*]}]
set_input_delay -clock {sdram_clk} -min 2.5 [get_ports {DRAM_DQ[*]}]

# sdram_clk leads CLOCK_50, so by default read data launched by an SDRAM
# clock edge would be captured by the CLOCK_50 edge 2.143 ns later. The
# controller captures it on the CLOCK_50 edge after that one (CAP_AT in
# sdram_ctrl). The default hold check, against the earlier CLOCK_50 edge,
# is already the correct one.
set_multicycle_path -setup -end 2 -from [get_clocks {sdram_clk}] -to [get_clocks {CLOCK_50}]
set_multicycle_path -hold -end 0 -from [get_clocks {sdram_clk}] -to [get_clocks {CLOCK_50}]


#**************************************************************
# SRAM
#**************************************************************

# vga_gen presents an SRAM address and captures the pixel data on the next
# VGA clock (39.682 ns), so the round trip through the 10 ns SRAM is split
# into a budget of 15 ns from the VGA clock to the address pins, 1 ns of
# board delay and 10 ns of SRAM access time, leaving the rest of the period
# from the data pins to the capturing register.
set sram_read_outputs [get_ports {SRAM_ADDR[*] SRAM_OE_N SRAM_CE_N}]

set_output_delay -clock [get_clocks $clk_vga] -max 24.682 $sram_read_outputs
set_output_delay -clock [get_clocks $clk_vga] -min  0.000 $sram_read_outputs

set_input_delay -clock [get_clocks $clk_vga] -max 26.000 [get_ports {SRAM_DQ[*]}]
set_input_delay -clock [get_clocks $clk_vga] -min  3.000 [get_ports {SRAM_DQ[*]}]

# ppu_video_ram_mux registers the write address and data on CLOCK_50, and
# the write strobe falls and rises within the following clock. Values are
# for the 10 ns IS61LV25616AL:
#   tSA 0 (address setup to write start), tHA 0 (address hold from write end)
#   tSD 6 (data setup to write end), tHD 0 (data hold from write end)
# CE_N is gated the same way as WE_N, so only WE_N is used as the reference
set_output_delay -clock {sram_we_clk} -clock_fall -max 0.000 -add_delay [get_ports {SRAM_ADDR[*]}]
set_output_delay -clock {sram_we_clk} -min 0.000 -add_delay [get_ports {SRAM_ADDR[*]}]

set_output_delay -clock {sram_we_clk} -max 6.000 [get_ports {SRAM_DQ[*]}]
set_output_delay -clock {sram_we_clk} -min 0.000 [get_ports {SRAM_DQ[*]}]


#**************************************************************
# Asynchronous and Slow I/O
#**************************************************************

# Switches, PS/2, LEDs, the audio codec, and VGA DAC have no meaningful
# relationship to the FPGA clocks at these speeds
set_false_path -from [get_ports {SW[*] PS2_CLK PS2_DAT}]
set_false_path -to [get_ports {LEDR[*] LEDG[*] PS2_CLK PS2_DAT}]
set_false_path -to [get_ports {I2C_SCLK I2C_SDAT}]
set_false_path -to [get_ports {AUD_BCLK AUD_DACDAT AUD_DACLRCK AUD_XCK}]
set_false_path -to [get_ports {VGA_R[*] VGA_G[*] VGA_B[*] VGA_HS VGA_VS}]

# sdram_rom waits FLASH_READ_CLKS clocks after changing the flash address
# before sampling the flash data, which covers the flash access time
set_false_path -to [get_ports {FL_ADDR[*] FL_OE_N FL_WE_N FL_RST_N}]
set_false_path -from [get_ports {FL_DQ[*]}]


#**************************************************************
# Multicycle Paths
#**************************************************************

# sdram_rom starts each SDRAM read 2 clocks after the PPU clock enable that
# updates the NES file bus address, and the read data is registered at least
# 2 clocks before the next PPU clock enable, so paths between the NES core
# and the SDRAM controller have 2 clocks
set_multicycle_path -setup -end 2 -from [get_registers {*nes_soc_ocram:nes|*}] -to [get_registers {*sdram_ctrl:ctrl|*}]
set_multicycle_path -hold -end 1 -from [get_registers {*nes_soc_ocram:nes|*}] -to [get_registers {*sdram_ctrl:ctrl|*}]
set_multicycle_path -setup -end 2 -from [get_registers {*sdram_ctrl:ctrl|*}] -to [get_registers {*nes_soc_ocram:nes|*}]
set_multicycle_path -hold -end 1 -from [get_registers {*sdram_ctrl:ctrl|*}] -to [get_registers {*nes_soc_ocram:nes|*}]

# The NES core registers only update on cpu_en or ppu_en, which are at least
# 9 clocks apart (clk_en). The on-chip RAMs only write on cpu_ram_en or
# ppu_ram_en, which come 4 or 5 clocks after a PPU enable and 4 or 5 clocks
# before the next one. Their address registers load every clock, but the
# address only has to be right at the RAM enable and at the clock before the
# next core enable, and the read data only has to be right at the next core
# enable, so paths into and out of the RAMs get 4 clocks as well. clk_en
# itself updates every clock and is deliberately left out, except for
# ppu_sync and odd_cpu_cycle, which only change on the clocks where a PPU
# enable is consumed. RAM to RAM paths are left at 1 clock.
set nes_soc {*|nes_soc_ocram:nes|nes_soc:soc}

set nes_core_regs [get_registers [list \
    "$nes_soc|cpu:nes_cpu|*" \
    "$nes_soc|apu:nes_apu|*" \
    "$nes_soc|ppu:nes_ppu|*" \
    "$nes_soc|oam_dma:nes_oam_dma|*" \
    "$nes_soc|joystick_io:nes_joystick_io|*" \
    "$nes_soc|file_bus_mux:file_mux|*" \
    "$nes_soc|reg.*" \
    "$nes_soc|cart_irq" \
    "$nes_soc|clk_en:nes_clk_en|ppu_sync" \
    "$nes_soc|clk_en:nes_clk_en|reg_odd_cpu_cycle" \
    {*nes_de1:nes|reg_audio_cpu_clk*}]]

set nes_ram_regs [get_registers {*|nes_soc_ocram:nes|*syncram_sp:*}]

set_multicycle_path -setup -end 4 -from $nes_core_regs -to $nes_core_regs
set_multicycle_path -hold -end 3 -from $nes_core_regs -to $nes_core_regs
set_multicycle_path -setup -end 4 -from $nes_core_regs -to $nes_ram_regs
set_multicycle_path -hold -end 3 -from $nes_core_regs -to $nes_ram_regs
set_multicycle_path -setup -end 4 -from $nes_ram_regs -to $nes_core_regs
set_multicycle_path -hold -end 3 -from $nes_ram_regs -to $nes_core_regs
