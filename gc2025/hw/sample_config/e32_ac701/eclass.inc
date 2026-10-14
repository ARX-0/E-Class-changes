# E-class RV32 config for the AC701 build option (derived from e-class branch 92 base-sim/soc_config.inc)
ISA=RV32IMAC
MUL=asic
SYNTH=FPGA
VERBOSITY=0
USERTRAPS=enable
USER=enable
COREFABRIC=AXI4Lite
MULSTAGES=8
DIVSTAGES=32
PADDR=32
RESETPC=4096
ARITHTRAP=disable

CAUSESIZE=6
DEBUG=disable
OPENOCD=disable
DTVEC_BASE=0

# Verilator options
COVERAGE=none
TRACE=disable
THREADS=1
VERILATESIM=fast

# DebugOptions
RTLDUMP=disable
ASSERTIONS=disable

# Trigger Setup
TRIGGERS=2

# performance counters
COUNTERS=0

# pmpsize
PMP=enable
PMPSIZE=4
# FPGA part and top come from the GC2025 BOARD table (ac701_eclass -> xc7a200tfbg676-2, fpga_top)
