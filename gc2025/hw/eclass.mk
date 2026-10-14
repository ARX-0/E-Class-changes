# ------------------------------------------------------------------------------------------------ #
# 32-bit E-class build option for GC2025 (included by Makefile when CORE=eclass).
#   make build CORE=eclass BOARD=ac701_eclass XLEN_build=32
# Sources: E-class repo (gitlab.com/shaktiproject/cores/e-class, master = 1.10.2) under eclass/:
#   eclass/src            core RTL                      eclass/{Soc.bsv,Soc.defines,sign_dump.bsv} base-sim SoC
#   eclass/{common_bsv,common_verilog,devices,fabrics}  deps pinned by e-class base-sim/manager.sh
#   eclass/FpgaSoc.bsv    FPGA top SoC (base-sim TbSoc.bsv without the simulation-only parts)
# Nothing here touches the C-class build: own build dir, own Vivado project (fpga_project_eclass).
# ------------------------------------------------------------------------------------------------ #
ECLASS_DIR      := eclass
ECLASS_CONFIG   ?= sample_config/e32_$(subst _eclass,,$(BOARD))/eclass.inc
ECLASS_BUILD    := build_eclass
ECLASS_VDIR     := $(ECLASS_BUILD)/verilog
ECLASS_BDIR     := $(ECLASS_BUILD)/intermediate
ECLASS_BOARD    := boards/$(BOARD)
ECLASS_PROGRAM  ?=
# Main memory 2^18 = 256 KB (base-sim default 2^25 = 32 MB does not fit FPGA BRAM).
ECLASS_ADDR_SPACE ?= 18
BSC_LIB_DIR     := $(dir $(shell which bsc))../lib

include $(ECLASS_CONFIG)

# ---- define macros: same rules as e-class base-sim/Makefile ------------------------------------ #
ECLASS_DEFINES := -D Addr_space=$(ECLASS_ADDR_SPACE)
ifneq (,$(findstring RV64,$(ISA)))
  ECLASS_DEFINES += -D RV64=True
  ECLASS_XLEN=64
endif
ifneq (,$(findstring RV32,$(ISA)))
  ECLASS_DEFINES += -D RV32=True
  ECLASS_XLEN=32
endif
ifneq (,$(findstring M,$(ISA)))
  ifeq ($(MUL), fpga)
    ECLASS_DEFINES += -D muldiv_fpga=True -D muldiv=True
  else
    ECLASS_DEFINES += -D $(MUL)=True -D muldiv=True
  endif
endif
ifneq (,$(findstring A,$(ISA)))
  ECLASS_DEFINES += -D atomic=True
endif
ifneq (,$(findstring C,$(ISA)))
  ECLASS_DEFINES += -D compressed=True
endif
ifeq ($(SYNTH),SIM)
  ECLASS_DEFINES += -D simulate=True
endif
ifeq ($(USERTRAPS), enable)
  ECLASS_DEFINES += -D usertraps=True
endif
ifeq ($(USER), enable)
  ECLASS_DEFINES += -D user=True
endif
ifeq ($(RTLDUMP), enable)
  ECLASS_DEFINES += -D rtldump=True
endif
ifeq ($(ASSERTIONS), enable)
  ECLASS_DEFINES += -D ASSERT=True
endif
ifeq ($(PMP), enable)
  ECLASS_DEFINES += -D pmp=True
endif
ifeq ($(ARITHTRAP), enable)
  ECLASS_DEFINES += -D arith_trap=True
endif
ifeq ($(DEBUG), enable)
  ECLASS_DEFINES += -D debug=True
endif
ifeq ($(OPENOCD), enable)
  ECLASS_DEFINES += -D openocd=True
endif
ifneq ($(TRIGGERS), 0)
  ECLASS_DEFINES += -D triggers=True -D trigger_num=$(TRIGGERS) -D mcontext=0 -D scontext=0
endif
ifneq ($(COUNTERS), 0)
  ECLASS_DEFINES += -D perfmonitors=True -D counters=$(COUNTERS)
endif
ECLASS_DEFINES += -D VERBOSITY=$(VERBOSITY) -D CORE_$(COREFABRIC)=True \
                  -D MULSTAGES=$(MULSTAGES) -D DIVSTAGES=$(DIVSTAGES) \
                  -D Counters=$(COUNTERS) -D paddr=$(PADDR) -D vaddr=$(ECLASS_XLEN) \
                  -D PMPSIZE=$(PMPSIZE) -D resetpc=$(RESETPC) -D causesize=$(CAUSESIZE) \
                  -D DTVEC_BASE=$(DTVEC_BASE)

# ---- include path: same as e-class base-sim/Makefile, rooted at eclass/ ------------------------ #
E := $(ECLASS_DIR)
ECLASS_BSVINC := $(E)/fpga_stubs:$(E):%/Prelude:%/Libraries:%/Libraries/BlueNoC:$(E)/src/core/:$(E)/src/core/m_ext/:$(E)/fabrics/axi4:$(E)/fabrics/axi4lite:$(E)/devices/bootrom:$(E)/devices/pwm:$(E)/devices/uart:$(E)/devices/clint:$(E)/devices/bram:$(E)/devices/riscvDebug013:$(E)/devices/jtagdtm/:$(E)/devices/err_slave/:$(E)/common_bsv/:$(E)/common_verilog/

# bsc options = e-class base-sim/Makefile with the 3 compile fixes (-K4000M, no basicinout filter).
ECLASS_BSCOPTS := +RTS -K4000M -RTS -check-assert -keep-fires -opt-undetermined-vals \
                  -remove-false-rules -remove-empty-rules -remove-starved-rules -remove-dollar \
                  -suppress-warnings G0020 -unspecified-to X

.PHONY: build_eclass eclass_generate_verilog eclass_boot_files eclass_program eclass_ip_build eclass_board_build eclass_mcs eclass_clean
build_eclass: eclass_generate_verilog eclass_boot_files eclass_program eclass_ip_build eclass_board_build eclass_mcs

eclass_generate_verilog: ## E-class: BSV -> Verilog (top mkFpgaSoc)
	@mkdir -p $(ECLASS_VDIR) $(ECLASS_BDIR)
	bsc -u -verilog -elab -vdir $(ECLASS_VDIR) -bdir $(ECLASS_BDIR) -info-dir $(ECLASS_BDIR) \
	  $(ECLASS_DEFINES) $(ECLASS_BSCOPTS) -p $(ECLASS_BSVINC) -g mkFpgaSoc $(E)/FpgaSoc.bsv
	@for f in RegFile BRAM2BELoad BRAM2BE BRAM2; do cp $(BSC_LIB_DIR)/Verilog.Vivado/$$f.v $(ECLASS_VDIR)/; done
	@for f in FIFO2 FIFO1 FIFO10 RevertReg FIFO20 FIFOL1 SyncFIFO Counter SizedFIFO RegFileLoad SyncReset0 \
	  SyncRegister MakeClock UngatedClockMux ClockInverter MakeResetA MakeReset0 SyncResetA ResetEither \
	  SyncHandshake SyncFIFO1 BRAM1Load BRAM1; do cp $(BSC_LIB_DIR)/Verilog/$$f.v $(ECLASS_VDIR)/ 2>/dev/null || true; done
	@cp $(E)/common_verilog/bram_1r1w.v $(E)/common_verilog/bram_1rw.v $(ECLASS_VDIR)/
	@echo "E-class Verilog ready in $(ECLASS_VDIR)"

eclass_boot_files: ## E-class: boot ROM image (device tree), trimmed to the 8192-entry boot ROM
	@echo "XLEN=$(ECLASS_XLEN)" > $(E)/dts/Makefile.inc
	@$(MAKE) -C $(E)/dts
	@cut -c1-8 $(E)/dts/boot.hex | head -n 8192 > $(ECLASS_VDIR)/boot.MSB
	@if [ "$(ECLASS_XLEN)" = "64" ]; then cut -c9-16 $(E)/dts/boot.hex | head -n 8192 > $(ECLASS_VDIR)/boot.LSB; \
	  else cp $(ECLASS_VDIR)/boot.MSB $(ECLASS_VDIR)/boot.LSB; fi
	@echo "boot.MSB/LSB: $$(wc -l < $(ECLASS_VDIR)/boot.MSB) lines"

eclass_program: ## E-class: main-memory init (code.mem) from ECLASS_PROGRAM=<elf> (empty memory if unset)
ifneq ($(ECLASS_PROGRAM),)
	elf2hex $$(( $(ECLASS_XLEN) / 8 )) $$(( (1 << $(ECLASS_ADDR_SPACE)) / ($(ECLASS_XLEN) / 8) )) $(ECLASS_PROGRAM) 2147483648 > $(ECLASS_VDIR)/code.mem
else
	@for i in $$(seq 1 $$(( (1 << $(ECLASS_ADDR_SPACE)) / ($(ECLASS_XLEN) / 8) ))); do echo 00000000; done > $(ECLASS_VDIR)/code.mem
endif
	@echo "code.mem: $$(wc -l < $(ECLASS_VDIR)/code.mem) words"

eclass_ip_build: ## E-class: clock divider IP
	vivado -log $(ECLASS_BUILD)/ipbuild.log -nojournal -mode tcl -notrace -source $(ECLASS_BOARD)/tcl/create_ip_project.tcl \
	  -tclargs $(FPGA) $(JOBS) || (echo "Could not create IP project"; exit 1)

eclass_board_build: ## E-class: Vivado project, synthesis, implementation, bitstream
	vivado -nojournal -nolog -mode tcl -notrace -source $(ECLASS_BOARD)/tcl/create_project.tcl \
	  -tclargs $(SYNTHTOP) $(FPGA) $(ECLASS_VDIR) || (echo "Could not create core project"; exit 1)
	vivado -nojournal -log $(ECLASS_BUILD)/vivado_build.log -notrace -mode tcl -source $(ECLASS_BOARD)/tcl/run.tcl -tclargs $(JOBS)
	@test -f fpga_project_eclass/e-class/e-class.runs/core_impl_1/$(SYNTHTOP).bit || (echo "ERROR: no bitstream"; exit 1)

eclass_mcs: ## E-class: flash image
	vivado -nojournal -nolog -mode tcl -source $(ECLASS_BOARD)/tcl/generate_mcs.tcl

eclass_clean:
	rm -rf $(ECLASS_BUILD) fpga_project_eclass
