#set curdir [ file dirname [ file normalize [ info script ] ] ]
#source $curdir/env.tcl
#
#open_project $ip_project_dir/$ip_project.xpr
#set_property "simulator_language" "Mixed" [current_project]
#set_property "target_language" "Verilog" [current_project]

puts "\nDEBUG: Creating Clock Divider from Clock Wizard\n"

if { [get_ips -quiet clk_divider] eq "" } {
    create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name clk_divider 
} else {
    reset_run clk_divider_synth_1
}

set_property -dict [list \
												CONFIG.Component_Name {clk_divider} \
												CONFIG.CLK_IN1_BOARD_INTERFACE {sys_diff_clock} \
												CONFIG.CLKOUT2_USED {true} \
												CONFIG.CLKOUT3_USED {true} \
												CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50} \
												CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {200} \
												CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
												CONFIG.PRIM_IN_FREQ {200.000} \
												CONFIG.CLKIN1_JITTER_PS {50.0} \
                        CONFIG.MMCM_DIVCLK_DIVIDE {1} \
												CONFIG.MMCM_CLKFBOUT_MULT_F {5.000} \
												CONFIG.MMCM_CLKIN1_PERIOD {5.000} \
												CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
                        CONFIG.MMCM_CLKOUT0_DIVIDE_F {25.000} \
												CONFIG.MMCM_CLKOUT1_DIVIDE {10} \
												CONFIG.MMCM_CLKOUT2_DIVIDE {5} \
												CONFIG.NUM_OUT_CLKS {3} \
												CONFIG.CLKOUT1_JITTER {135.255} \
												CONFIG.CLKOUT1_PHASE_ERROR {89.971} \
												CONFIG.CLKOUT2_JITTER {112.316} \
												CONFIG.CLKOUT2_PHASE_ERROR {89.971} \
												CONFIG.CLKOUT3_JITTER {98.146} \
												CONFIG.CLKOUT3_PHASE_ERROR {89.971}] [get_ips clk_divider]

generate_target {instantiation_template} [get_ips clk_divider]
create_ip_run [get_ips clk_divider]

