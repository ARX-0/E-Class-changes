#!/usr/bin/env bash
# Status board for scripts/build_eclass_gc2025.sh (refreshes every 10 s; run it in its own terminal).
#   GC2025_HW  path to gc2025/hw (default: current directory)
#   LOG_DIR    log folder used by the build script (default: ./logs)
GC2025_HW=$(cd "${GC2025_HW:-.}" && pwd)
LOG_DIR=$(cd "${LOG_DIR:-./logs}" 2>/dev/null && pwd || echo "${LOG_DIR:-./logs}")
RUNS="$GC2025_HW/fpga_project_eclass/e-class/e-class.runs"
STAGES="G_env G_bsc G_boot G_prog G_ip G_impl G_mcs"
while true; do
  clear
  printf '\033[1mGC2025: make build CORE=eclass BOARD=ac701_eclass XLEN_build=32\033[0m   %s  (refresh 10s)\n' "$(date +%T)"
  printf '%-8s %-10s %-10s %s\n' STAGE VERDICT TIME DETAIL
  sfail=0; npass=0
  for s in $STAGES; do
    f="$LOG_DIR/$s.log"
    if [ ! -f "$f" ]; then printf '%-8s \033[90m%-10s\033[0m\n' "$s" PENDING; continue; fi
    ex=$(grep -oE '^exit=[0-9]+' "$f" | tail -1 | cut -d= -f2)
    t=$(grep -m1 '^real' "$f" | awk '{print $2}')
    d=$(grep -E '^RESULT:' "$f" | tail -1)
    if [ -z "$ex" ]; then v=RUNNING; c=33
      [ -z "$d" ] && d=$(grep -E '^compiling |Phase|Starting|Finished|_design|write_bitstream' "$f" | tail -1)
    elif [ "$ex" = 0 ]; then v=PASS; c=32; npass=$((npass+1))
    else v="FAIL($ex)"; c=31; sfail=1; [ -z "$d" ] && d=$(grep -m1 -E 'ERROR|Error' "$f"); fi
    printf '%-8s \033[%sm%-10s\033[0m %-10s %s\n' "$s" "$c" "$v" "${t:-}" "$(echo "${d:0:90}" | tr -s ' ')"
  done
  T="$RUNS/core_impl_1/fpga_top_timing_summary_routed.rpt"
  [ -f "$T" ] && echo "timing: $(grep -m1 -A2 'WNS(ns)' "$T" | tail -1 | awk '{print "WNS "$1" ns, WHS "$5" ns"}')"
  [ -f "$RUNS/core_impl_1/fpga_top.bit" ] && echo -e "\033[32mbitstream: $RUNS/core_impl_1/fpga_top.bit\033[0m"
  if [ $sfail = 1 ]; then echo -e "\033[1;31mOVERALL: FAILED (see logs)\033[0m"
  elif [ $npass = 7 ]; then echo -e "\033[1;32mOVERALL: DONE\033[0m"
  else echo -e "\033[1;33mOVERALL: IN PROGRESS ($npass/7)\033[0m"; fi
  sleep 10
done
