## -----------------------------------------------------------------------
## Makefile — run all MAC testbenches with Icarus Verilog (iverilog / vvp)
##
## Usage:
##   make all        — compile + run every testbench
##   make tb_<name>  — compile + run one specific testbench
##   make clean      — remove generated files
##
## Dependencies: iverilog, vvp  (sudo apt install iverilog)
## -----------------------------------------------------------------------

SRCDIR  := .
TBDIR   := .

# Source files (DUT)
SRCS := $(SRCDIR)/DFF.v \
        $(SRCDIR)/ripple_carry4.v \
        $(SRCDIR)/carry_select_adders.v \
        $(SRCDIR)/compressors.v \
        $(SRCDIR)/controller.v \
        $(SRCDIR)/multiplicand.v \
        $(SRCDIR)/multiplier_1.v \
        $(SRCDIR)/multiplier_2.v

# Testbench files — one module per file; each file may contain multiple modules
TESTBENCHES := \
    tb_ripple_carry4 \
    tb_carry_select4 \
    tb_carry_select16 \
    tb_carry_select32 \
    tb_compressor_3_2 \
    tb_compressor_4_2 \
    tb_compressor_adder_16 \
    tb_DFF \
    tb_MULTIPLICAND \
    tb_CONTROLLER \
    tb_multiplier_paper2 \
    tb_multiplier_paper1

# Map each top-level module name to the file it lives in
TB_FILE_tb_ripple_carry4        := tb_ripple_carry4.v
TB_FILE_tb_carry_select4        := tb_carry_select_adders.v
TB_FILE_tb_carry_select16       := tb_carry_select_adders.v
TB_FILE_tb_carry_select32       := tb_carry_select_adders.v
TB_FILE_tb_compressor_3_2       := tb_compressors.v
TB_FILE_tb_compressor_4_2       := tb_compressors.v
TB_FILE_tb_compressor_adder_16  := tb_compressors.v
TB_FILE_tb_DFF                  := tb_dff_multiplicand.v
TB_FILE_tb_MULTIPLICAND         := tb_dff_multiplicand.v
TB_FILE_tb_CONTROLLER           := tb_controller.v
TB_FILE_tb_multiplier_paper2    := tb_multipliers.v
TB_FILE_tb_multiplier_paper1    := tb_multipliers.v

.PHONY: all clean $(TESTBENCHES)

all: $(TESTBENCHES)

define RUN_TB
$(1):
	@echo ""
	@echo "========================================================"
	@echo " Running $(1)"
	@echo "========================================================"
	iverilog -g2012 -o sim_$(1) -s $(1) $(SRCS) $(TB_FILE_$(1))
	vvp sim_$(1)
endef

$(foreach tb,$(TESTBENCHES),$(eval $(call RUN_TB,$(tb))))

clean:
	rm -f sim_tb_* *.vcd

