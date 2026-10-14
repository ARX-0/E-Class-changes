# IP for the E-class AC701 option: only the clock divider (same clk_wiz config as boards/ac701).
set curdir [ file dirname [ file normalize [ info script ] ] ]
source $curdir/env.tcl
if { $argc != 2 } { puts "usage: -tclargs <fpga-part> <jobs>"; exit 2 }
set fpga_part [lindex $argv 0]
set jobs [lindex $argv 1]
file mkdir $fpga_dir
create_project -force $ip_project -dir $ip_project_dir -part $fpga_part
set_property "target_language" "Verilog" [current_project]
set_property board_part xilinx.com:ac701:part0:1.4 [current_project]
source $curdir/create_clock_div.tcl
set run_list [get_runs *_synth_1]
launch_runs $run_list -jobs $jobs
foreach my_run $run_list {wait_on_run $my_run}
exit
