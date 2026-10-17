# Writes detailed TimeQuest reports for the NES project into timing/
#
# Run from board/de1 after a full compile:
#   quartus_sta -t timing_report.tcl

project_open NES

create_timing_netlist
read_sdc
update_timing_netlist

file mkdir timing

# Constraint sanity: unmatched or ignored SDC commands, missing clocks,
# unconstrained ports
check_timing -file timing/check_timing.txt
report_sdc -ignored -file timing/ignored_constraints.txt
report_ucp -file timing/unconstrained.txt

report_clocks -file timing/clocks.txt
report_clock_transfers -file timing/clock_transfers.txt
report_clock_fmax_summary -file timing/fmax.txt

create_timing_summary -setup -file timing/summary_setup.txt
create_timing_summary -hold -file timing/summary_hold.txt

# Worst paths into each clock domain, with full clock paths so the PLL
# and DRAM_CLK latencies are visible
foreach_in_collection clk [get_clocks] {
    set name [get_clock_info -name $clk]
    regsub -all {[^A-Za-z0-9_]} $name {_} file_name

    report_timing -setup -to_clock $name -npaths 20 -detail full_path \
        -file timing/setup_$file_name.txt
    report_timing -hold -to_clock $name -npaths 20 -detail full_path \
        -file timing/hold_$file_name.txt
}

# Worst path to each of the worst CLOCK_50 endpoints, to see which parts of
# the design are failing rather than many variations of the same path
report_timing -setup -to_clock {CLOCK_50} -npaths 500 -nworst 1 \
    -detail summary -file timing/endpoints_CLOCK_50.txt

# Paths into and out of the on-chip NES RAMs, to confirm the core multicycle
# applies to them (the relationship should be 80 ns, except RAM to RAM)
set nes_ram_regs [get_registers {*|nes_soc_ocram:nes|*syncram_sp:*}]
report_timing -setup -from $nes_ram_regs -npaths 20 -detail summary \
    -file timing/nes_ram_out.txt
report_timing -setup -to $nes_ram_regs -npaths 20 -detail summary \
    -file timing/nes_ram_in.txt

# I/O paths for the external memories
foreach {label ports} {
    sdram {DRAM_*}
    sram  {SRAM_*}
} {
    report_timing -setup -to [get_ports $ports] -npaths 20 -detail full_path \
        -file timing/${label}_out_setup.txt
    report_timing -hold -to [get_ports $ports] -npaths 20 -detail full_path \
        -file timing/${label}_out_hold.txt
    report_timing -setup -from [get_ports $ports] -npaths 20 -detail full_path \
        -file timing/${label}_in_setup.txt
    report_timing -hold -from [get_ports $ports] -npaths 20 -detail full_path \
        -file timing/${label}_in_hold.txt
}

delete_timing_netlist

# Hold is usually worst in the fast model, which the reports above do not
# cover
create_timing_netlist -fast_model
read_sdc
update_timing_netlist

create_timing_summary -setup -file timing/fast_summary_setup.txt
create_timing_summary -hold -file timing/fast_summary_hold.txt

report_timing -hold -npaths 20 -nworst 1 -detail summary \
    -file timing/fast_hold_worst.txt

foreach {label ports} {
    sdram {DRAM_*}
    sram  {SRAM_*}
} {
    report_timing -hold -to [get_ports $ports] -npaths 20 -detail full_path \
        -file timing/fast_${label}_out_hold.txt
    report_timing -hold -from [get_ports $ports] -npaths 20 -detail full_path \
        -file timing/fast_${label}_in_hold.txt
}

delete_timing_netlist
project_close
