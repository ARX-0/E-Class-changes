/*
FPGA top-level SoC for the E-class core, built only from E-class repo products:
  - E-class core + SoC: gitlab.com/shaktiproject/cores/e-class (master, base-sim/Soc.bsv)
  - BRAM main memory and boot ROM: the same devices E-class base-sim/TbSoc.bsv uses
This is base-sim/TbSoc.bsv with the simulation-only parts removed (UART user model, $fwrite logs,
$finish, OpenOCD BDPI). The UART pins are brought out to the FPGA instead.
*/
package FpgaSoc;
  import Soc :: *;
  import Clocks :: *;
  import Connectable :: *;
`ifdef CORE_AXI4
  import AXI4_Types :: *;
  import AXI4_Fabric :: *;
`elsif CORE_AXI4Lite
  import AXI4_Lite_Types :: *;
  import AXI4_Lite_Fabric :: *;
`endif
  import uart :: *;
  import common_types :: *;
  `include "common_params.bsv"
  `include "Soc.defines"
  import bram :: *;
  import bootrom :: *;

  interface Ifc_FpgaSoc;
    (*prefix="uart0"*)
    interface RS232 uart_io;
  endinterface

  (*synthesize*)
  module mkFpgaSoc(Ifc_FpgaSoc);
    // Debug/JTAG is disabled in this build, so the core clock/reset are passed for tck/trst (unused).
    let def_clk <- exposeCurrentClock;
    let def_rst <- exposeCurrentReset;
    Ifc_Soc soc <- mkSoc(def_clk, def_rst);

  `ifdef CORE_AXI4
    Ifc_bram_axi4#(`paddr, XLEN, USERSPACE, `Addr_space) main_memory <- mkbram_axi4(`MemoryBase,
                                                                          "code.mem", "MainMEM");
    Ifc_bootrom_axi4#(`paddr, XLEN, USERSPACE, 13) bootrom <- mkbootrom_axi4(`BootRomBase);
  `elsif CORE_AXI4Lite
    Ifc_bram_axi4lite#(`paddr, XLEN, USERSPACE, `Addr_space) main_memory <-
                                          mkbram_axi4lite(`MemoryBase, "code.mem", "MainMEM");
    Ifc_bootrom_axi4lite#(`paddr, XLEN, USERSPACE, 13) bootrom <- mkbootrom_axi4lite(`BootRomBase);
  `endif

    mkConnection(soc.main_mem_master, main_memory.slave);
    mkConnection(soc.boot_mem_master, bootrom.slave);

    interface uart_io = soc.uart_io;
  endmodule
endpackage: FpgaSoc
