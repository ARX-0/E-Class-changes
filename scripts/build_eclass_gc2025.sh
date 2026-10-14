#!/usr/bin/env bash
# Staged build of the 32-bit E-class option in a GC2025 checkout:
#   make build CORE=eclass BOARD=ac701_eclass XLEN_build=32
# Stages: G_env G_bsc G_boot G_prog G_ip G_impl G_mcs  ->  $LOG_DIR/G_<stage>.log (each ends with "exit=<rc>")
#
# Settings (environment variables):
#   GC2025_HW      path to gc2025/hw with the E-class files applied (default: current directory)
#   VIVADO_BIN     folder containing Vivado 2024.2 'vivado'   (default: whatever 'vivado' is on PATH)
#   BSC_BIN        folder containing bsc 2025.01.1 'bsc'      (default: whatever 'bsc' is on PATH)
#   ECLASS_PROGRAM ELF loaded into main memory, relative to GC2025_HW (default: empty memory)
#   LOG_DIR        where logs go (default: ./logs)
# The Vivado license must already be set in your environment (XILINXD_LICENSE_FILE / LM_LICENSE_FILE).
set -u
GC2025_HW=$(cd "${GC2025_HW:-.}" && pwd)
LOG_DIR=$(mkdir -p "${LOG_DIR:-./logs}" && cd "${LOG_DIR:-./logs}" && pwd)
[ -n "${VIVADO_BIN:-}" ] && PATH="$VIVADO_BIN:$PATH"     # Vivado 2024.2 must come FIRST on PATH
[ -n "${BSC_BIN:-}" ] && PATH="$BSC_BIN:$PATH" && export BLUESPECDIR="$BSC_BIN/../lib"
export PATH

M=(make -C "$GC2025_HW" CORE=eclass BOARD=ac701_eclass XLEN_build=32 "ECLASS_PROGRAM=${ECLASS_PROGRAM:-}")
stage() { local n=$1; shift
  { echo "== $n $(date '+%F %T')"; echo "\$ $*"; } > "$LOG_DIR/$n.log"
  ( time "$@" ) >> "$LOG_DIR/$n.log" 2>&1; local rc=$?
  echo "exit=$rc" >> "$LOG_DIR/$n.log"; return $rc; }

{ echo "vivado: $(vivado -version 2>/dev/null | head -1)"; echo "bsc: $(bsc -v 2>&1 | head -1)"; } > "$LOG_DIR/G_env.log"
if grep -q "v2024.2" "$LOG_DIR/G_env.log" && grep -q "2025.01.1" "$LOG_DIR/G_env.log"; then echo "exit=0" >> "$LOG_DIR/G_env.log"
else echo "RESULT: need vivado v2024.2 and bsc 2025.01.1 first on PATH"; echo "exit=1"; fi >> "$LOG_DIR/G_env.log"
grep -q "^exit=0" "$LOG_DIR/G_env.log" || exit 1

stage G_bsc  "${M[@]}" eclass_generate_verilog || exit 1
stage G_boot "${M[@]}" eclass_boot_files       || exit 1
stage G_prog "${M[@]}" eclass_program          || exit 1
stage G_ip   "${M[@]}" eclass_ip_build         || exit 1

RUNS="$GC2025_HW/fpga_project_eclass/e-class/e-class.runs"
# Stream Vivado's own run logs into G_impl.log so progress is visible while it runs.
( sleep 20; tail -n +1 -F "$RUNS/core_synth_1/runme.log" "$RUNS/core_impl_1/runme.log" 2>/dev/null \
  | grep --line-buffered -E "^(Phase|Starting|Finished)|_design completed|write_bitstream|readmem|ERROR|CRITICAL WARNING" \
  >> "$LOG_DIR/G_impl.log" ) & TAILER=$!
stage G_impl "${M[@]}" eclass_board_build; rc=$?
kill $TAILER 2>/dev/null; pkill -P $TAILER 2>/dev/null
if [ $rc = 0 ] && grep -q "write_bitstream completed successfully" "$RUNS/core_impl_1/runme.log" 2>/dev/null; then
  echo "RESULT: bitstream $RUNS/core_impl_1/fpga_top.bit" >> "$LOG_DIR/G_impl.log"
else
  echo "RESULT: NO bitstream" >> "$LOG_DIR/G_impl.log"; sed -i 's/^exit=0$/exit=1/' "$LOG_DIR/G_impl.log"; exit 1
fi
stage G_mcs "${M[@]}" eclass_mcs
