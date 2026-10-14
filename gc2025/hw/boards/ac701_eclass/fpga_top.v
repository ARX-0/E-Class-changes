// AC701 top level for the 32-bit E-class build option.
// 200 MHz differential board clock -> clk_divider (same IP config as boards/ac701) -> 50 MHz core clock.
// cpu_reset button (active high) and MMCM lock produce a synchronised active-low reset for the SoC.
module fpga_top (
  input  sys_clk_p,
  input  sys_clk_n,
  input  sys_rst,
  input  uart0_SIN,
  output uart0_SOUT
);
  wire core_clk, clk_200_unused, clk_100_unused, locked;

  clk_divider clk_div (
    .clk_in1_p (sys_clk_p),
    .clk_in1_n (sys_clk_n),
    .clk_out1  (core_clk),
    .clk_out2  (clk_100_unused),
    .clk_out3  (clk_200_unused),
    .reset     (sys_rst),
    .locked    (locked)
  );

  // 2-flop reset synchroniser: reset is released synchronously to core_clk once the MMCM is locked.
  reg [1:0] rst_sync = 2'b00;
  always @(posedge core_clk or negedge locked)
    if (!locked) rst_sync <= 2'b00;
    else         rst_sync <= {rst_sync[0], 1'b1};

  mkFpgaSoc soc (
    .CLK        (core_clk),
    .RST_N      (rst_sync[1]),
    .uart0_SIN  (uart0_SIN),
    .uart0_SOUT (uart0_SOUT)
  );
endmodule
