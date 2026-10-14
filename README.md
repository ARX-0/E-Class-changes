## Tools & versions (rebuild reference)

Use these exact versions to rebuild or reproduce anything in this document. Every version below was read from the tool itself.

| tool | exact version | used for |
|---|---|---|
| Bluespec compiler (bsc) | `Bluespec Compiler, version 2025.01.1 (build 65e3a87a)` | BSV → Verilog |
| Verilator | `Verilator 5.034 2025-02-24 rev v5.034` | Verilog → simulator |
| RISC-V GCC | `riscv32-unknown-elf-gcc (xPack GNU RISC-V Embedded GCC x86_64) 14.3.0` | test programs |
| Spike (upstream riscv-isa-sim, not Shakti mod-spike) | `Spike RISC-V ISA Simulator 1.1.1-dev` | reference model + boot device tree |
| elf2hex | from the same riscv-isa-sim install (no version flag) | program → memory image |
| Device-tree compiler | `DTC 1.6.1` | boot ROM image |
| Xilinx Vivado | `vivado v2024.2 (64-bit)` | FPGA synthesis, implementation, bitstream |
| Vivado AC701 board files | revision `1.4` | AC701 builds |
| GNU Make / Python / Perl | `4.3` / `3.10.12` / `5.34.0` | build and test scripts |
| Host | Ubuntu 22.04.5 LTS, 16 cores, 62 GB RAM | |

**Environment notes for anyone rebuilding:**
- Put **Vivado 2024.2 first on `PATH`**. If another Vivado (e.g. 2025.1) is set up first, plain `vivado` will run that one instead.
- Set `BLUESPECDIR` to the `lib` folder of bsc 2025.01.1.
- For GCC 12 and later, spell out the CSR/fence extensions in the ISA string: `rv32imac_zicsr_zifencei`.
- bsc builds older than 2025.01.1 may accept `-K40000M`; 2025.01.1 rejects it (see Q2).

# SHAKTI E-class core: master build status, test results and FPGA support

**Summary**
1. The E-class core logic on `master` is correct. It passed 63 of 63 RV32 ISA tests, matching the reference simulator instruction by instruction.
2. `master` fails to compile only because of 3 outdated settings in `base-sim/Makefile`. They were written for older tools (commercial Bluespec, a bsc that accepted a 40 GB stack, Verilator 4). Fixing those 3 lines makes it build. Running software needs 4 small extra steps (see Q2).
3. Branch `89-fix-compilation` already contains those 3 fixes. The e-class repo has simulation support but no FPGA flow. The FPGA flow for this core lives in the shakti-soc repo.
4. A 32-bit E-class option was added to the GC2025 build (`make build CORE=eclass BOARD=ac701_eclass XLEN_build=32`). It produces an AC701 bitstream from e-class repo sources with all timing met, and leaves the C-class builds unchanged (see Q5; not yet tested on a board).

**What's in this repository**

| path | what it is |
|---|---|
| `README.md` | this document |
| [`e-class-patches/`](e-class-patches/) | ready-to-apply fixes for the e-class repo (`master`) and the benchmarks repo, described in Q2 |
| [`gc2025/hw/`](gc2025/hw/) | the 32-bit E-class build option for GC2025 (Q5), laid out like GC2025's `hw/` folder, plus [`Makefile.eclass.patch`](gc2025/hw/Makefile.eclass.patch) for GC2025's `hw/Makefile` |
| [`scripts/`](scripts/) | [`build_eclass_gc2025.sh`](scripts/build_eclass_gc2025.sh) (staged build with one log per stage) and [`status_eclass_gc2025.sh`](scripts/status_eclass_gc2025.sh) (10-second status board) |

**Repositories referred to in this document**

| repo | branch / commit | used for |
|---|---|---|
| https://gitlab.com/shaktiproject/cores/e-class | `master` = commit `e8a0dfd` = tag `1.10.2` | main subject: `src/core` (core RTL), `base-sim` (test SoC + Makefile) |
| same | `92-e-class-simulator-is-not-working` = commit `536f03b` (master + 1 commit, nothing under `src/` changed) | the "92 works" branch |
| same | `89-fix-compilation` (unmerged; head commit `009c896`) | earlier fix attempt |
| https://gitlab.com/shaktiproject/cores/shakti-soc | `master` = commit `0299467`, path `asic/e-class-aardonyx` | context only: Aardonyx SoC, which uses e-class `1.10.2` |
| https://gitlab.com/shaktiproject/gc2025 | `main` = commit `110c386` | see Q5 |

Dependencies pulled by `base-sim/manager.sh` on e-class `master` (all under https://gitlab.com/shaktiproject):

| dependency repo | version pinned by e-class `base-sim` | version pinned by shakti-soc `asic/e-class-aardonyx` |
|---|---|---|
| `uncore/devices` | tag `5.0.2` (`c622ad1`) | tag `6.3.0` (`b5b31d4`) |
| `uncore/fabrics` | tag `1.2.0` (`c3d6da4`) | tag `1.2.0` (`c3d6da4`) |
| `common_bsv` | declared `master`; built with tag `3.2.0` (`42d7768`) | declared `master`; tag `3.2.0` (`42d7768`) |
| `common_verilog` | declared `master`; built with tag `3.2.0` (`029a150`) | declared `master`; tag `3.2.0` (`029a150`) |
| `verification_environment/verification` | tag `3.2.6` (`4e72ce9`); its `riscv-tests` submodule at `fbf5f3a` | not used |
| `cores/benchmarks` | declared `master`; built with tag `1.1.0` (`654ef7f`) | not used |

Note: `common_bsv`, `common_verilog` and `benchmarks` are pinned to the moving `master` branch, so a future rebuild may pick up newer code. Pin them to the tags above for a reproducible build.

---

## Q1. "E-class Aardonyx works on the FPGA AC701 (proven)" [shakti-soc repo, context for the e-class repo]

**Short answer:** Yes. A separate team ran it on the board and reported that it works. We did not run it on a board ourselves, but we rebuilt the AC701 bitstream independently, and it builds cleanly and meets timing for the core.

- **What it is:** the Aardonyx SoC, in shakti-soc `master` (`0299467`), at `asic/e-class-aardonyx`. Its AC701 flow is in `asic/e-class-aardonyx/fpga/test/ac701-eval`.
- **Link to the e-class repo:** Aardonyx pins `e-class@1.10.2`, which is the **same commit as e-class `master`** (`e8a0dfd`). The core RTL on the FPGA is therefore identical to `master`.
- **Board test:** done by a separate team, who report that it works. That result is theirs.
- **Our independent rebuild** with Vivado 2024.2 (bitstream generated; **not loaded onto a board**):

| item | result |
|---|---|
| FPGA | Xilinx AC701, Artix-7 `xc7a200tfbg676-2` |
| Clock | 200 MHz board clock, divided to a 50 MHz core clock (MMCM) |
| Setup timing (is the logic fast enough?) | **met**, WNS **+3.750 ns** at 50 MHz |
| Hold timing (does data change too early?) | WHS **−0.339 ns**, **189 failing endpoints**, **all in the PWM peripheral's clock-crossing synchronizers** (`pwm_cluster/pwm0..pwm5`), **0 in the E-class core** |
| Resources | LUT 28,454 (**21.3 %**), FF 30,519 (**11.4 %**), **4 DSP**, 0 BRAM |
| On-chip power | **0.341 W** |
| Build time | about 12.5 minutes (bsc 49 s, clock IP 2 min 23 s, synthesis + implementation 8 min 35 s, flash image 35 s) |

- **To build with current open-source bsc:** the Aardonyx Makefile has the same `-K40000M` problem as e-class (see Q2, fix 1). We built it with `-K4000M` set on the `make` command line.
- **What the hold violations mean:** PWM outputs could glitch on the board. The CPU, memory bus, UART and debug are not on these paths. The fix belongs in the AC701 constraints file, not in the core (see Recommendations).
- **Note:** the e-class repo itself has **no FPGA flow** (see Q4).

---

## Q2. "Does it work on e-class master? What changes are needed when compiling?" [e-class repo]

**Short answer:** Yes. The core on `master` compiles, simulates and passes the ISA tests. To compile, exactly **3 lines in `base-sim/Makefile`** must change. **No change is needed in `src/core`.**

### The 3 compile fixes, and the exact error each one removes

| # | stage | what is wrong in `base-sim/Makefile` (e-class `master`) | exact error with current tools | fix |
|---|---|---|---|---|
| 1 | bsc (BSV → Verilog) | `+RTS -K40000M` asks for a 40 GB stack; current bsc allows at most 4 GiB | `bsc: error in RTS option -K40000M: size outside allowed range (0 - 4294967295)`, so bsc stops before compiling anything | `-K40000M` → `-K4000M` |
| 2 | bsc (BSV → Verilog) | `-verilog-filter ${BLUESPECDIR}/bin/basicinout`. `basicinout` shipped only with the old commercial Bluespec; open-source bsc does not have it | `basicinout: not found`, then `Error: Command line: (G0121) Verilog filter ... basicinout returned ...`, so bsc stops after the first module | delete the `VERILOG_FILTER` block |
| 3 | Verilator (Verilog → simulator) | bsc writes `#0;` delays; Verilator 5 requires an explicit timing option | `%Error-NEEDTIMINGOPT: verilog/mkcsrfile.v:2342:5: Use --timing or --no-timing to specify how delays should be handled` | add `--no-timing` to `VERILATOR_FLAGS` |

With these 3 changes, `master` builds end to end: bsc compiles 23 modules with 0 errors (about 21 s), Verilator builds the simulator (about 12 s), and the boot files generate correctly.

### Exact diff (e-class `master`, file `base-sim/Makefile`)

Ready-to-apply file: [`e-class-patches/01-base-sim-Makefile-compile-fixes.patch`](e-class-patches/01-base-sim-Makefile-compile-fixes.patch) (`git apply` in an e-class `master` checkout).

In the diffs below, `<SHAKTI_TOOLS>` stands for the Makefile's `${TOOLS_DIR}` + `shakti-tools` folder (Shakti-internal tools, not public).

```diff
--- a/base-sim/Makefile
+++ b/base-sim/Makefile
@@ -131,7 +131,7 @@
 # ----------------------------------------------------------------------------------------------- #
 
 # ----------------- Setting up flags for verilator ---------------------------------------------- #
-VERILATOR_FLAGS += --stats -O3 $(verilate_fast) -LDFLAGS "-static" --x-assign fast \
+VERILATOR_FLAGS += --stats --no-timing -O3 $(verilate_fast) -LDFLAGS "-static" --x-assign fast \
 									 --x-initial fast --noassert sim_main.cpp --bbox-sys -Wno-STMTDLY \
 									 -Wno-UNOPTFLAT -Wno-WIDTH -Wno-lint -Wno-COMBDLY -Wno-INITIALDLY \
 									 --autoflush $(coverage) $(trace) --threads $(THREADS) \
@@ -140,21 +140,13 @@
 
 # ---------------- Setting the variables for bluespec compile  --------------------------------- #
 BSC_CMD:= bsc -u -verilog -elab 
-BSVCOMPILEOPTS:= +RTS -K40000M -RTS -check-assert  -keep-fires -opt-undetermined-vals \
+BSVCOMPILEOPTS:= +RTS -K4000M -RTS -check-assert  -keep-fires -opt-undetermined-vals \
 								 -remove-false-rules -remove-empty-rules -remove-starved-rules -remove-dollar \
 								 -suppress-warnings G0020 -show-schedule -show-module-use
 BSVLINKOPTS:=-parallel-sim-link 8 -keep-fires
 VERILOGDIR:=./verilog/
 BSVBUILDDIR:=./bsv_build/
 BSVOUTDIR:=./bin
-ifeq (, $(wildcard <SHAKTI_TOOLS>/insert_license.sh))
-  VERILOG_FILTER:= -verilog-filter ${BLUESPECDIR}/bin/basicinout
-else
-  VERILOG_FILTER:= -verilog-filter ${BLUESPECDIR}/bin/basicinout \
-									 -verilog-filter <SHAKTI_TOOLS>/insert_license.sh \
-									 -verilog-filter ./rename_translate.sh
-	VERILOGLICENSE:= cp <SHAKTI_TOOLS>/IITM_LICENSE.txt ${VERILOGDIR}/LICENSE.txt
-endif
 # ----------------------------------------------------------------------------------------------- #
 
 # ------------------------------------- Makefile TARGETS ---------------------------------------- #
```

### Extra steps needed to run software (not needed just to compile)

| item | where | problem | fix |
|---|---|---|---|
| Compiler flag | build command / ISA string | GCC 12 and later need `_zicsr` (and `_zifencei`) spelled out. Error: `Error: unrecognized opcode 'csrr a0,instret', extension 'zicsr' required` | use `-march=rv32imac_zicsr` (or `rv32imac_zicsr_zifencei`) |
| Boot files | e-class `base-sim/Makefile`, target `generate_boot_files` | generated boot files have 8,350 lines but the boot ROM holds 8,192. Error: `%Error: boot.LSB:8192: $readmem file address beyond bounds of array` | trim `bin/boot.MSB` and `bin/boot.LSB` to 8,192 lines (the `base-sim` README already says to do this by hand) |
| Signature writer | e-class `base-sim/sign_dump.bsv`, lines 123 and 213 | writes test results with `%4h`, which drops leading zeros (`ff00ff` instead of `00ff00ff`), so 10 correct tests are reported as `FAIL_SIGN` | change `%4h` → `%8h` ([`02-sign_dump-zero-padded-signature.patch`](e-class-patches/02-sign_dump-zero-padded-signature.patch)) |
| Console output | benchmarks repo (`cores/benchmarks`, `master`), `common/syscalls.c`, `putchar` | the UART wait loop has inverted polarity: it waits while the transmitter has room, so `printf` programs hang forever | change `bnez a1, uart_status_simple` → `beqz a1, uart_status_simple` ([`benchmarks-putchar-polarity.patch`](e-class-patches/benchmarks-putchar-polarity.patch)). Branch 92's README documents the same bug for the shakti-sdk `putchar` |

With all of the above in place, a "Hello, World!" program prints correctly and exits on its own.

### Correctness: RV32 ISA regression on e-class `master`

- **What we ran:** the official RISC-V ISA tests (`riscv-tests`), using the e-class repo's own regression scripts from the verification repo (tag `3.2.6`). Config was RV32IMAC.
- **How a test passes:** each test passes only if all three of these hold:
  1. Every retired instruction (PC, instruction, register written, value) matches the reference simulator, line by line.
  2. The memory signature matches.
  3. The test's own self-check reports pass (`tohost = 1`).
- **Reference model:** upstream spike `1.1.1`. Its commit log was reformatted into the core's trace format, without changing any values. We did this because the repo's scripts expect Shakti's modified spike, which was not available. We checked the reformatting by hand on the `add` test: 464 instructions, identical.

| suite | what it tests | tests | trace matches spike | self-check passed |
|---|---|---|---|---|
| rv32ui | base integer instructions | 39 | 39 | 39 |
| rv32um | multiply / divide | 8 | 8 | 8 |
| rv32ua | atomics (AMO, LR/SC) | 10 | 10 | 10 |
| rv32uc | compressed instructions | 1 | 1 | 1 |
| rv32mi | `shamt` | 1 | 1 | 1 |
| rv32mi | `ma_addr`, `ma_fetch` (misaligned access/fetch traps) | 2 | 2 | 2 |
| **total** | | **63** | **63 / 63** | **63 / 63** |

- **Two tests needed a workaround:** `ma_addr` and `ma_fetch` use the old CSR name `mbadaddr` (renamed `mtval` in 2017), so they do not compile with today's assembler. We compiled them with `-Dmbadaddr=mtval`, and both then matched spike. The real fix belongs in the verification repo's copy of riscv-tests.
- **Not tested (6 machine-mode tests):** `csr`, `mcsr`, `scall`, `sbreak`, `breakpoint`, `illegal`. They are commented out in the e-class repo's own test list, `verification/verif-scripts/core_configs/eclass-riscv-tests.list`. CSR access, ecall/ebreak and illegal-instruction traps are therefore not covered by this result.
- **Repos unchanged:** every run was done from copies, and no file in the e-class repo or its dependencies was modified.

---

## Q3. "Will master work if we merge branch 92 and change a few flags?" [e-class repo]

**Short answer:** Yes, but only some of branch 92 should be kept.

**What branch 92 changes** (`536f03b`, compared with `master`, file `base-sim/Makefile`):

```diff
-ifeq (, $(wildcard <SHAKTI_TOOLS>/insert_license.sh))
-  VERILOG_FILTER:= -verilog-filter ${BLUESPECDIR}/bin/basicinout
-else
-  VERILOG_FILTER:= -verilog-filter ${BLUESPECDIR}/bin/basicinout \
-									 -verilog-filter <SHAKTI_TOOLS>/insert_license.sh \
-									 -verilog-filter ./rename_translate.sh
-	VERILOGLICENSE:= cp <SHAKTI_TOOLS>/IITM_LICENSE.txt ${VERILOGDIR}/LICENSE.txt
-endif
+BLUESPECDIR:=<hardcoded developer path>/bsc/inst/lib
```
(`<hardcoded developer path>` is a folder in one developer's home directory; the exact value is in the commit.)
Branch 92 also changes `check-env` slightly, and in `base-sim/soc_config.inc` it sets `ISA=RV32IMAC` and `DIVSTAGES=32`. It changes nothing under `src/`.

**What to do:**

| change | take it? |
|---|---|
| Branch 92's removal of the `basicinout` filter (fix 2) | **Yes, keep** |
| Add `-K4000M` (fix 1); branch 92 still has `-K40000M` | **Yes, add** |
| Add `--no-timing` to `VERILATOR_FLAGS` (fix 3); branch 92 does not have it | **Yes, add** |
| Branch 92's hardcoded `BLUESPECDIR:=...` line | **No.** This is a hardcoded developer path that exists only on one person's machine; it breaks the build everywhere else |

- **Branch 92 alone fails here:** with current open-source bsc, branch 92 as-is fails at fix 1 (the `-K40000M` error). With only `-K4000M` added, it compiles the same 23 modules as `master` with the 3 fixes. This confirms that the only real difference between `master` and branch 92 is the `basicinout` removal.

**Why "branch 92 works" for its author:**
- Branch 92 fixes only problem 2.
- It works on the author's machine because that setup uses a different bsc build, which accepts the 40 GB stack setting (problem 1).
- It also uses Verilator 4.106, which branch 92's README pins. Verilator 4 does not need `--no-timing` (problem 3).
- With the current open-source bsc 2025.01.1 and Verilator 5, branch 92 fails.

**Recommended route:** merge `89-fix-compilation`, or cherry-pick its `base-sim/Makefile` changes, rather than merging 92.
- Branch 89 already has `-K4000M` and `--no-timing`, and drops `basicinout`.
- In place of `basicinout`, branch 89 uses the repo's own `./rename_translate.sh` filter. We have not built branch 89 itself; the 3-line diff in Q2 is the version we verified.
- Small cleanup needed if branch 89 is taken: its `else` branch (used only when Shakti's internal tools are installed) contains a doubled `-verilog-filter -verilog-filter`, which should be fixed.
- Branch 89 also moves the boot-file generation to `base-sim/bootcode/` and switches the riscv-tests patch. Review those separately.

---

## Q4. "Does E-class have FPGA simulation and support?" [e-class repo]

| capability | in the e-class repo? | details |
|---|---|---|
| **Simulation** | **Yes** | `base-sim/Makefile` has targets for Verilator (`link_verilator`, the one we verified), Synopsys VCS (`link_vcs`), Cadence NCVerilog/irun (`link_ncverilog`, `link_irun`) and Mentor ModelSim (`link_msim`), plus `regress`, `test`, `torture`, `aapg`, `csmith` |
| **FPGA** | **No** | no Vivado scripts, no constraint (`.xdc`) files and no board files in the e-class repo |
| FPGA-readiness of the `base-sim` SoC | **No** (found while building Q5) | `base-sim/Soc.bsv` always instantiates the test-signature device from `base-sim/sign_dump.bsv`, which writes a host file with `$fopen`. Vivado rejects the generated Verilog: `ERROR: [Synth 8-36] 'TASK_fopen___d3' is not declared [mksign_dump_axi4lite.v:781]`. To put the e-class SoC on an FPGA, this device must be made simulation-only (e.g. wrapped in `` `ifdef simulate ``) or replaced by a synthesizable version |
| FPGA-related option | partial | `MUL=fpga` selects `src/core/m_ext/muldiv_fpga.bsv`. That module needs a Xilinx multiplier IP, which the repo does not generate |

**Where the FPGA flows for this core actually are** (shakti-soc repo, `master` `0299467`):

| board | path in shakti-soc |
|---|---|
| AC701 (Aardonyx SoC) | `asic/e-class-aardonyx/fpga/test/ac701-eval` (the flow we rebuilt in Q1) |
| Arty A7-100T (Aardonyx SoC) | `asic/e-class-aardonyx/fpga/test/artya7-100t`, `asic/e-class-aardonyx/fpga/test/artya7-100t-eval` |
| Arty A7-35T | `fpga/boards/artya7-35t/e-class` |
| Arty A7-100T | `fpga/boards/artya7-100t/e-class` |
| Nexys 4 DDR | `fpga/boards/nexys4DDR/e-class` |

---

## Q5. "Can the 32-bit E-class become a build option in GC2025, next to C-class ganga (64) and yamuna (32)?" [gc2025 repo + e-class repo]

**Short answer: Yes. It was built and works up to a bitstream.** We added an E-class option to the GC2025 build (a copy of `gc2025` `main`, commit `110c386`) and produced an AC701 bitstream from **e-class repo sources only** (`master` = `1.10.2`), with all timing met. The C-class ganga and yamuna builds are unchanged. It was not loaded onto a board.

**How the two flows differ, and how we joined them**

| | GC2025 (C-class) | E-class repo |
|---|---|---|
| Core configuration | YAML specs (`hw/sample_config/c32_<board>/…`) → `soc_config` → generated `makefile.inc` | flat config file (`base-sim/soc_config.inc`) → `-D` macros in `base-sim/Makefile` |
| Libraries | `deps.yaml`: devices `9.0.1`, fabrics `1.3.6`, common_bsv `3.1.0`, plus csrbox, caches_mmu | `base-sim/manager.sh`: devices `5.0.2`, fabrics `1.2.0`, common_bsv/common_verilog `3.2.0` |
| FPGA flow | built in: `hw/boards/<board>/` + `make build BOARD=…` | none (see Q4) |

Merging the two at the **source-template level** is a separate porting project. The E-class core would have to move to GC2025's much newer libraries, whose interfaces have changed. Instead we joined them at the **build-command level**: one Makefile, with a `CORE` switch. Each core keeps its own proven libraries.

```
make build BOARD=ac701 XLEN_build=64                     # C-class ganga   (unchanged)
make build BOARD=ac701 XLEN_build=32                     # C-class yamuna  (unchanged)
make build CORE=eclass BOARD=ac701_eclass XLEN_build=32  # NEW: E-class 32
```

**What was added** (proposed change to `gc2025` `main`; nothing existing is modified apart from the 3 Makefile hunks below):

| new file / folder in `gc2025/hw/` | content |
|---|---|
| [`eclass.mk`](gc2025/hw/eclass.mk) | the E-class build steps: bsc with the e-class `base-sim/Makefile` macro rules and its 3 compile fixes from Q2, boot ROM image, program image, Vivado IP/project/bitstream/flash. Own output folders (`build_eclass/`, `fpga_project_eclass/`), so C-class outputs are never touched |
| `eclass/` | e-class repo sources: `src/` (core) and `base-sim/Soc.bsv`, `Soc.defines`, `sign_dump.bsv` from e-class `master`, plus the e-class-pinned libraries (devices `5.0.2`, fabrics `1.2.0`, common_bsv/common_verilog `3.2.0`). For a real merge, fetch these via a `deps.yaml`-style pin list |
| [`eclass/FpgaSoc.bsv`](gc2025/hw/eclass/FpgaSoc.bsv) | small FPGA top: the e-class `base-sim/TbSoc.bsv` with the simulation-only parts removed (BRAM main memory + boot ROM + UART pins) |
| [`eclass/fpga_stubs/sign_dump.bsv`](gc2025/hw/eclass/fpga_stubs/sign_dump.bsv) | synthesizable stand-in for the e-class test-signature device (same interface, no file I/O). Needed because of the Q4 finding |
| [`sample_config/e32_ac701/eclass.inc`](gc2025/hw/sample_config/e32_ac701/eclass.inc) | E-class RV32IMAC configuration (from e-class branch `92` `base-sim/soc_config.inc`, with simulation-only options off and `MUL=asic`) |
| [`boards/ac701_eclass/`](gc2025/hw/boards/ac701_eclass/) | `fpga_top.v` (200 MHz → 50 MHz clock, reset, UART), `constraints.xdc` (pins copied from GC2025 `boards/ac701`), `tcl/` (the clock IP script from GC2025 `boards/ac701`, unchanged, plus project, synthesis and flash scripts in GC2025 style) |

The **only edits to an existing GC2025 file**, `hw/Makefile` (ready-to-apply: [`gc2025/hw/Makefile.eclass.patch`](gc2025/hw/Makefile.eclass.patch)):
```diff
@@ board table @@
 else ifeq ($(BOARD), ac701)
 	FPGA:=xc7a200tfbg676-2
 	MCS:=true
+else ifeq ($(BOARD), ac701_eclass)
+	FPGA:=xc7a200tfbg676-2
+	MCS:=true
@@ after MOREDEFINES @@
+# Core selection: CORE=cclass (default: ganga 64 / yamuna 32) or CORE=eclass (32-bit E-class, see eclass.mk)
+CORE ?= cclass
+ifeq ($(CORE), eclass)
+include eclass.mk
+endif
@@ targets @@
 default: quick_build_xilinx
+ifeq ($(CORE), eclass)
+build:  build_eclass
+else
 build:  quick_build
+endif
```

**Proof that C-class is unaffected:** `make -n build` (the list of commands make would run) is **identical** with the original and the modified Makefile, for `BOARD=ac701` 32/64, `arty_a7_yamuna` and `arty_a7_ganga`.

**Result of the E-class 32 build** (Vivado 2024.2, AC701 `xc7a200tfbg676-2`, 50 MHz):

| item | result |
|---|---|
| Bitstream + flash image | ✅ `fpga_top.bit`, `fpga_top.mcs` |
| Setup timing | **met**, WNS **+3.922 ns** |
| Hold timing | **met**, WHS **+0.075 ns** (0 failing paths) |
| Critical warnings | **0** |
| Resources | LUT 7,080 (**5.3 %**), FF 4,627 (**1.7 %**), **72 BRAM (19.7 %)** for 256 KB main memory + boot ROM, 4 DSP |
| On-chip power | 0.267 W |
| Program in memory | a "Hello, World!" test program (UART output), loaded into the BRAM image; Vivado confirms the boot ROM and memory images were read |
| Build time | about 8 minutes (clock IP 1 min 18 s, synthesis + implementation 5 min 44 s, flash image 35 s) |

**Things to know before adopting it:**
1. **Not tested on a board yet.** The next step is to load it on an AC701 and check that "Hello, World!" appears on the USB-UART at the e-class UART's default baud rate.
2. **The signature device is replaced by a stub** for FPGA builds, which is fine for hardware. The proper fix is in the e-class repo (Q4 row "FPGA-readiness").
3. **`MUL=asic`** (pure-Bluespec multiply/divide) is used. The e-class `MUL=fpga` option needs a Xilinx multiplier IP that neither repo generates.
4. **Main memory is 256 KB of on-chip BRAM.** The base-sim default (32 MB) doesn't fit on the FPGA, and the test program's 128 KB stack needs more than 128 KB. There's no DDR memory controller for E-class yet.
5. **The E-class option keeps its own older libraries.** Moving it onto GC2025's newer libraries (true source-level unification) is optional follow-up work, and the larger task.

---

## How to rebuild the E-class 32 option in GC2025

Use the tool versions at the top of this document. Commands use only the official repositories plus this one.

```bash
# 1. GC2025 at the tested commit, plus the files from this repository
git clone https://gitlab.com/shaktiproject/gc2025.git && cd gc2025 && git checkout 110c386
git clone https://github.com/ARX-0/E-Class-changes.git ../E-Class-changes   # this repository
cp -r ../E-Class-changes/gc2025/hw/. hw/
git apply hw/Makefile.eclass.patch
cd hw/eclass

# 2. E-class sources (master = tag 1.10.2) and the libraries it pins, at the exact tags used
git clone --recursive -b 1.10.2 https://gitlab.com/shaktiproject/cores/e-class.git e-class
cp -r e-class/src src
cp e-class/base-sim/Soc.bsv e-class/base-sim/Soc.defines e-class/base-sim/sign_dump.bsv .
git clone --recursive -b 5.0.2 https://gitlab.com/shaktiproject/uncore/devices.git devices
git clone --recursive -b 1.2.0 https://gitlab.com/shaktiproject/uncore/fabrics.git fabrics
git clone --recursive -b 3.2.0 https://gitlab.com/shaktiproject/common_bsv.git common_bsv
git clone --recursive -b 3.2.0 https://gitlab.com/shaktiproject/common_verilog.git common_verilog
git clone -b 3.2.6 https://gitlab.com/shaktiproject/verification_environment/verification.git verification
cp -r verification/dts dts

# 3. Test program: "Hello, World!" over the UART (benchmarks 1.1.0 + the putchar fix)
git clone -b 1.1.0 https://gitlab.com/shaktiproject/cores/benchmarks.git benchmarks
git -C benchmarks apply ../../../../E-Class-changes/e-class-patches/benchmarks-putchar-polarity.patch
mkdir -p programs
riscv32-unknown-elf-gcc -march=rv32imac_zicsr -DCONFIG_RISCV64=True -DCUSTOM=True -mcmodel=medany -static \
  -std=gnu99 -O2 -ffast-math -fno-common -fno-builtin-printf -w -nostartfiles -lgcc \
  -I benchmarks/common -T benchmarks/common/link.ld -o programs/hello.riscv \
  benchmarks/hello/hello.c benchmarks/common/syscalls.c benchmarks/common/crt.S
cd ..

# 4. Build (Vivado 2024.2 and bsc 2025.01.1 first on PATH; Vivado license set in your environment)
make build CORE=eclass BOARD=ac701_eclass XLEN_build=32 ECLASS_PROGRAM=eclass/programs/hello.riscv
#    or, with one log per stage and a live status board in a second terminal:
#    ECLASS_PROGRAM=eclass/programs/hello.riscv ../../E-Class-changes/scripts/build_eclass_gc2025.sh
#    ../../E-Class-changes/scripts/status_eclass_gc2025.sh
```
Result: `fpga_project_eclass/e-class/e-class.runs/core_impl_1/fpga_top.bit` and `fpga_project_eclass/e-class/fpga_top.mcs`. The C-class builds (`make build BOARD=… XLEN_build=32|64`) are unaffected.

**To apply the e-class fixes from Q2** (in an e-class `master` checkout):
```bash
git apply e-class-patches/01-base-sim-Makefile-compile-fixes.patch
git apply e-class-patches/02-sign_dump-zero-padded-signature.patch
```

---

## Recommendation / next steps

1. **[e-class repo] Fix the build:** merge `89-fix-compilation` into `master`, or apply its 3 `base-sim/Makefile` fixes (`-K4000M`, remove `basicinout`, add `--no-timing`). Do not take branch 92's hardcoded `BLUESPECDIR` line.
2. **[e-class repo] Fix the signature writer:** in `base-sim/sign_dump.bsv` (lines 123 and 213), change `%4h` → `%8h`. This removes 10 false `FAIL_SIGN` results.
3. **[e-class repo] Automate the boot trim:** make the `generate_boot_files` target in `base-sim/Makefile` trim `boot.MSB`/`boot.LSB` to 8,192 lines, so nobody has to do it by hand.
4. **[e-class repo] Re-enable the 6 disabled machine-mode tests** (`csr`, `mcsr`, `scall`, `sbreak`, `breakpoint`, `illegal`) in `verification/verif-scripts/core_configs/eclass-riscv-tests.list`, so that CSR and trap behaviour is tested. Also update the riscv-tests copy in the verification repo to use `mtval` instead of `mbadaddr`.
5. **[benchmarks repo] Fix `putchar`:** in `common/syscalls.c`, change `bnez` → `beqz` so `printf` programs do not hang. Also document `-march=..._zicsr` for GCC 12 and later.
6. **[shakti-soc repo] Fix FPGA hold timing:** add PWM clock constraints (a generated clock or false paths on the PWM synchronizers) to the AC701 constraints in `asic/e-class-aardonyx/fpga/test/ac701-eval`, or route the PWM clock through a global buffer (BUFG). Also change `-K40000M` → `-K4000M` in the Aardonyx Makefile.

7. **[e-class repo] Make the SoC FPGA-ready:** wrap the `sign_dump` instance in `base-sim/Soc.bsv` in `` `ifdef simulate `` (or make `sign_dump.bsv` synthesizable), so the e-class SoC can go to an FPGA without a stub.
8. **[gc2025 repo] Adopt the E-class 32 option (Q5):** add the files and 3 Makefile hunks from Q5, pin the E-class libraries in a `deps.yaml`-style list, then test the bitstream on an AC701 board (expect "Hello, World!" on the USB-UART).

**Status: the E-class repo investigation is complete and can be closed.**

---

## License

- Files derived from the **e-class** repository (`gc2025/hw/eclass/FpgaSoc.bsv`, `gc2025/hw/eclass/fpga_stubs/sign_dump.bsv`, `gc2025/hw/eclass.mk`, `e-class-patches/01-*`, `e-class-patches/02-*`) and the patch to the **benchmarks** repository follow those repositories' BSD-3-Clause license (Copyright IIT Madras). The upstream copyright notices apply.
- `gc2025/hw/boards/ac701_eclass/tcl/create_clock_div.tcl`, `run.tcl` and `generate_mcs.tcl` are unchanged copies from the GC2025 repository (`hw/boards/ac701/tcl/`), and `gc2025/hw/Makefile.eclass.patch` modifies GC2025's `hw/Makefile`. The GC2025 repository has no license file, so these remain under GC2025's own terms.
- The remaining new files (`scripts/`, `fpga_top.v`, `constraints.xdc`, the other tcl scripts, `eclass.inc`) may be used under the same BSD-3-Clause terms.
