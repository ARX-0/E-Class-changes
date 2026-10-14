# Vivado project for the E-class AC701 option (sources: E-class Verilog + fpga_top.v + constraints.xdc).
set curdir [ file dirname [ file normalize [ info script ] ] ]
source $curdir/env.tcl
if { $argc != 3 } { puts "usage: -tclargs <top-module> <fpga-part> <verilogdir>"; exit 2 }
set top_module [lindex $argv 0]
set fpga_part [lindex $argv 1]
set verilogdir [lindex $argv 2]
set base_version [string range [version -short] 0 3]
file mkdir $fpga_dir
create_project -force $core_project -dir $core_project_dir -part $fpga_part
set_property board_part xilinx.com:ac701:part0:1.4 [current_project]
set_property "target_language" "Verilog" [current_project]
add_files -norecurse -fileset [get_filesets sources_1] [glob $verilogdir/*.v] $board_dir/fpga_top.v
# $readmemh init files used by the E-class boot ROM (boot.MSB/LSB) and main-memory BRAM (code.mem)
foreach f {code.mem boot.MSB boot.LSB} {
  add_files -norecurse -fileset [get_filesets sources_1] $verilogdir/$f
  set_property file_type {Memory File} [get_files $verilogdir/$f]
}
set_property include_dirs $verilogdir [get_filesets sources_1]
set_property "top" $top_module [get_filesets sources_1]
add_files -norecurse -fileset constrs_1 $board_dir/constraints.xdc
import_ip $ip_project_dir/manage_ip.srcs/sources_1/ip/clk_divider/clk_divider.xci
if {[string equal [get_runs -quiet core_synth_1] ""]} {
  create_run -flow "Vivado Synthesis $base_version" -strategy "Vivado Synthesis Defaults" -constrset constrs_1 core_synth_1
}
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value " -verilog_define BSV_RESET_FIFO_HEAD -verilog_define BSV_RESET_FIFO_ARRAY -verilog_define BSV_ASYNC_RESET" -objects [get_runs core_synth_1]
current_run -synthesis [get_runs core_synth_1]
if {[string equal [get_runs -quiet core_impl_1] ""]} {
  create_run -flow "Vivado Implementation $base_version" -strategy "Vivado Implementation Defaults" -constrset constrs_1 -parent_run core_synth_1 core_impl_1
}
current_run -implementation [get_runs core_impl_1]
exit
