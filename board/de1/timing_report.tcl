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
project_close
