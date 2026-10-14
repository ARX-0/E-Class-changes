/*
FPGA-only stand-in for e-class base-sim/sign_dump.bsv (gitlab.com/shaktiproject/cores/e-class, master).

Why: e-class base-sim/Soc.bsv always instantiates the signature-dump device. The original writes test
signatures to a host file with $fopen/$fwrite, which is simulation-only; Vivado rejects the generated
Verilog ("'TASK_fopen___d3' is not declared"). This stand-in keeps the identical package, interface and
module names so Soc.bsv compiles unchanged, but does no file I/O:
  - slave: register writes (0x0 start, 0x8 end, 0xC end-of-sim) are accepted with OKAY; reads return 0
  - master: idle (never issues a memory read)
  - mv_end_simulation: True after a write to offset 0xC (same as the original)
Placed first on the bsc search path for FPGA builds only; simulation builds keep the original file.
*/
package sign_dump;
  import FIFOF :: *;
  import common_types :: *;
  `include "common_params.bsv"
  import AXI4_Types :: *;
  import AXI4_Fabric :: *;
  import AXI4_Lite_Types :: *;
  import AXI4_Lite_Fabric :: *;
  import Semi_FIFOF :: *;

`ifdef CORE_AXI4
  interface Ifc_sign_dump_axi4;
    interface AXI4_Master_IFC#(`paddr, XLEN, USERSPACE) master;
    interface AXI4_Slave_IFC#(`paddr, XLEN, USERSPACE) slave;
    method Bool mv_end_simulation;
  endinterface

  (*synthesize*)
  module mksign_dump_axi4(Ifc_sign_dump_axi4);
    AXI4_Master_Xactor_IFC #(`paddr, XLEN, USERSPACE) m_xactor <- mkAXI4_Master_Xactor;
    AXI4_Slave_Xactor_IFC #(`paddr, XLEN, USERSPACE) s_xactor <- mkAXI4_Slave_Xactor;
    Reg#(Bool) rg_end_sim <- mkRegA(False);

    rule accept_write;
      let aw <- pop_o (s_xactor.o_wr_addr);
      let w  <- pop_o (s_xactor.o_wr_data);
      if (aw.awaddr[3:0] == 'hc) rg_end_sim <= True;
      s_xactor.i_wr_resp.enq (AXI4_Wr_Resp {bresp: AXI4_OKAY, buser: aw.awuser, bid: aw.awid});
    endrule
    rule accept_read;
      let ar <- pop_o (s_xactor.o_rd_addr);
      s_xactor.i_rd_data.enq (AXI4_Rd_Data {rresp: AXI4_OKAY, rdata: 0, rlast: True,
                                            ruser: ar.aruser, rid: ar.arid});
    endrule

    interface master = m_xactor.axi_side;
    interface slave  = s_xactor.axi_side;
    method Bool mv_end_simulation = rg_end_sim;
  endmodule

`elsif CORE_AXI4Lite
  interface Ifc_sign_dump_axi4lite;
    interface AXI4_Lite_Master_IFC#(`paddr, XLEN, USERSPACE) master;
    interface AXI4_Lite_Slave_IFC#(`paddr, XLEN, USERSPACE) slave;
    method Bool mv_end_simulation;
  endinterface

  (*synthesize*)
  module mksign_dump_axi4lite(Ifc_sign_dump_axi4lite);
    AXI4_Lite_Master_Xactor_IFC #(`paddr, XLEN, USERSPACE) m_xactor <- mkAXI4_Lite_Master_Xactor;
    AXI4_Lite_Slave_Xactor_IFC #(`paddr, XLEN, USERSPACE) s_xactor <- mkAXI4_Lite_Slave_Xactor;
    Reg#(Bool) rg_end_sim <- mkRegA(False);

    rule accept_write;
      let aw <- pop_o (s_xactor.o_wr_addr);
      let w  <- pop_o (s_xactor.o_wr_data);
      if (aw.awaddr[3:0] == 'hc) rg_end_sim <= True;
      s_xactor.i_wr_resp.enq (AXI4_Lite_Wr_Resp {bresp: AXI4_LITE_OKAY, buser: aw.awuser});
    endrule
    rule accept_read;
      let ar <- pop_o (s_xactor.o_rd_addr);
      s_xactor.i_rd_data.enq (AXI4_Lite_Rd_Data {rresp: AXI4_LITE_OKAY, rdata: 0, ruser: ar.aruser});
    endrule

    interface master = m_xactor.axi_side;
    interface slave  = s_xactor.axi_side;
    method Bool mv_end_simulation = rg_end_sim;
  endmodule
`endif
endpackage
