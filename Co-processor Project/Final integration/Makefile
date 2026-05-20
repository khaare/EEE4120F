# =============================================================================
# Makefile — NIA Co-Processor Simulation
# Usage:
#   make sim_nia      — NIA P1 vs P2 comparison testbench
#   make sim_system   — StarCore -> NIA system testbench  
#   make timing       — static timing analysis (Paper 1 vs Paper 2)
#   make all          — all three
#   make clean        — remove compiled outputs
#
# Requires: iverilog + vvp (Icarus Verilog), python3
#   Install: sudo apt install iverilog python3
# =============================================================================

IVERILOG = iverilog
VVP      = vvp
PYTHON   = python3

SRC_MULT = multiplier_block
SRC_ACC  = add_accumulator

NIA_SRCS = \
	$(SRC_MULT)/DFF.v \
	$(SRC_MULT)/ripple_carry4.v \
	$(SRC_MULT)/carry_select_adders.v \
	$(SRC_MULT)/compressors.v \
	$(SRC_MULT)/multiplicand.v \
	$(SRC_MULT)/controller.v \
	$(SRC_MULT)/multiplier_1.v \
	$(SRC_MULT)/multiplier_2.v \
	$(SRC_ACC)/add_accumulator.v \
	NIA_Controller.v \
	NIA_Top_P1.v \
	NIA_Top_P2.v

.PHONY: all sim_nia sim_system timing clean

all: sim_nia sim_system timing

# ── NIA comparison testbench ──────────────────────────────────────────────────
sim_nia: tb_NIA_comparison
	@echo ""
	@echo "═══════════════════════════════════════════════════"
	@echo " NIA Co-Processor: Paper 1 vs Paper 2 Comparison"
	@echo "═══════════════════════════════════════════════════"
	$(VVP) tb_NIA_comparison | tee nia_results.txt

tb_NIA_comparison: tb_NIA_comparison.v $(NIA_SRCS) MAC_Controller.v
	$(IVERILOG) -g2012 -o $@ $^

# ── System-level testbench ────────────────────────────────────────────────────
sim_system: tb_StarCore_NIA
	@echo ""
	@echo "═══════════════════════════════════════════════════"
	@echo " StarCore-1 → NIA System Testbench"
	@echo "═══════════════════════════════════════════════════"
	$(VVP) tb_StarCore_NIA | tee system_results.txt

tb_StarCore_NIA: tb_StarCore_NIA.v $(NIA_SRCS) IO_Bus_NIA.v MAC_Controller.v
	$(IVERILOG) -g2012 -o $@ $^

# ── Static timing analysis ────────────────────────────────────────────────────
timing:
	@echo ""
	@echo "═══════════════════════════════════════════════════"
	@echo " Static Timing Analysis: Paper 1 vs Paper 2"
	@echo "═══════════════════════════════════════════════════"
	$(PYTHON) timing_analysis.py | tee timing_results.txt

clean:
	rm -f tb_NIA_comparison tb_StarCore_NIA *.vcd *.txt
