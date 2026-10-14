# AC701 constraints for the 32-bit E-class build option.
# Pin assignments copied from boards/ac701/constraints.xdc (C-class AC701 board files).
# The 200 MHz input clock is constrained by the clk_divider (clk_wiz) IP itself, as in boards/ac701.
set_property -dict { PACKAGE_PIN R3 IOSTANDARD DIFF_SSTL15 } [get_ports { sys_clk_p }];  # sysclk_p_i
set_property -dict { PACKAGE_PIN P3 IOSTANDARD DIFF_SSTL15 } [get_ports { sys_clk_n }];  # sysclk_n_i

set_property -dict { PACKAGE_PIN U4  IOSTANDARD LVCMOS15 } [get_ports { sys_rst }];     # cpu_reset_i
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS18 } [get_ports { uart0_SOUT }];  # usb_uart_rx_i
set_property -dict { PACKAGE_PIN T19 IOSTANDARD LVCMOS18 } [get_ports { uart0_SIN }];   # usb_uart_tx_i

# Asynchronous board inputs/outputs (button, UART at 115200 baud) have no timing relation to the core clock.
set_false_path -from [get_ports sys_rst]
set_false_path -from [get_ports uart0_SIN]
set_false_path -to   [get_ports uart0_SOUT]
