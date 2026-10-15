# SHAKTI E-class: build fixes

**Tools:** bsc 2025.01.1 · Verilator 5.034 · riscv32 GCC 14.3.0 · Spike 1.1.1 · Vivado 2024.2 · Linux, 4 cores, 8 GB RAM

## Problem
E-class `master` (`1.10.2`) does not build or run with current tools:
- bsc: `-K40000M` is out of range, and the `basicinout` filter is missing
- Verilator 5: `%Error-NEEDTIMINGOPT`
- `sign_dump` writes `%4h`, which drops leading zeros, so correct tests report `FAIL_SIGN`
- benchmarks `putchar` waits on the wrong UART status, so `printf` hangs

## Solution
[`01-base-sim-Makefile-compile-fixes.patch`](e-class-patches/01-base-sim-Makefile-compile-fixes.patch)
```diff
-VERILATOR_FLAGS += --stats -O3 $(verilate_fast) -LDFLAGS "-static" --x-assign fast \
+VERILATOR_FLAGS += --stats --no-timing -O3 $(verilate_fast) -LDFLAGS "-static" --x-assign fast \
-BSVCOMPILEOPTS:= +RTS -K40000M -RTS -check-assert  -keep-fires -opt-undetermined-vals \
+BSVCOMPILEOPTS:= +RTS -K4000M -RTS -check-assert  -keep-fires -opt-undetermined-vals \
-ifeq (, $(wildcard ${TOOLS_DIR}/shakti-tools/insert_license.sh))
-  VERILOG_FILTER:= -verilog-filter ${BLUESPECDIR}/bin/basicinout
-else
-  ... (rest of the VERILOG_FILTER block removed)
-endif
```
[`02-sign_dump-zero-padded-signature.patch`](e-class-patches/02-sign_dump-zero-padded-signature.patch) (2 places)
```diff
-      $fwrite(dump,"%4h\n", lv_data[31:0]);
+      $fwrite(dump,"%8h\n", lv_data[31:0]);
```
[`benchmarks-putchar-polarity.patch`](e-class-patches/benchmarks-putchar-polarity.patch) (benchmarks repo)
```diff
-        "bnez a1, uart_status_simple" "\n\t"
+        "beqz a1, uart_status_simple" "\n\t"
```

## Result
- `Hello, World!` prints and exits

GC2025 E-class 32: `make build CORE=eclass BOARD=ac701_eclass XLEN_build=32` ([gc2025/](gc2025/), [scripts/](scripts/)) · full notes: [archived/README.md](archived/README.md)
