#!/usr/bin/env python3
"""
================================================================================
 Static Timing Analysis — NIA Co-Processor Critical Path
 StarCore-1 HPES Project: Paper 1 (Compressor) vs Paper 2 (Carry-Select)
================================================================================
 Method: Manual gate-count critical-path analysis
 Process: 180nm CMOS (representative educational model)
 Gate delays (fan-out-of-4, FO4, units):
   NAND2: 1.0 FO4   INV: 0.5 FO4   XOR2: 1.5 FO4   MUX2: 1.5 FO4
 At 180nm: 1 FO4 ≈ 0.2 ns  →  scale all results to nanoseconds

 Critical paths analysed:
   Path A — Multiplier adder (per-cycle combinational delay through adder)
   Path B — Accumulator add (32→40-bit carry-select adder in add_accumulator)
   Path C — Overall MAC cycle: Multiplier adder + FSM overhead
================================================================================
"""

# ── Gate delay model (180nm FO4 units, 1 FO4 = 0.2 ns) ──────────────────────
FO4_NS = 0.2          # nanoseconds per FO4 unit
NAND2  = 1.0
INV    = 0.5
XOR2   = 1.5          # implemented as NAND-NAND tree
MUX2   = 1.5          # typically: INV + NAND2 + NAND2
AND2   = 1.0 + 0.5    # NAND2 + INV
OR2    = 1.0 + 0.5    # NOR2  + INV
FA     = XOR2 + NAND2 # full adder sum path: XOR chain ≈ 3.0 FO4

def ns(fo4):
    return fo4 * FO4_NS

# ═══════════════════════════════════════════════════════════════════════════════
# PAPER 1 — compressor_adder_16 critical path
# 4:2 Compressor cell (Figure 3, Reddy et al. 2018):
#   COX  = majority(A,B,C)        → 1 NAND2-based majority  ≈ 2.0 FO4
#   D1   = A XOR B XOR C          → 2-level XOR            ≈ 2×XOR2 = 3.0 FO4
#   S    = D1 XOR D XOR CIN       → 1 XOR2                 ≈ 1.5 FO4  (parallel)
#   CO   = MUX(D1,D,CIN)          → 1 MUX2                 ≈ 1.5 FO4  (parallel)
#
# The column chain: each bit column uses ONE 4:2 compressor.
# COX from column[i] → CIN of column[i+1]  (serial carry chain on COX)
# CO  from column[i] → D   of column[i+1]  (also serial)
#
# Critical path per compressor cell:
#   Input → COX: 2.0 FO4 (majority)
#   Input → S:   3.0 + 1.5 = 4.5 FO4 (D1 then S)
#   Worst: max(COX chain, S) propagates column to column
#   COX is computed independently of CIN (key Paper 1 claim!)
#   So within one column: COX delay = 2.0 FO4 (combinational, no CIN dependency)
#   S delay = D1(3.0) + XOR_with_CIN(1.5) = 4.5 FO4 from inputs
#
# 16-bit compressor_adder_16: 16 columns in parallel (COX/CO are inputs, not chain)
# The final SUM bits are all computed in ONE compressor cell depth (not chained SUM)
# COX propagates column-to-column: 16 columns × COX_delay
# But COX(col_i) is independent of CIN(col_i) — breaks carry chain!
# Actual chain: COX[i] feeds CIN[i+1] — this IS a chain but COX is fast (2.0 FO4)
# ═══════════════════════════════════════════════════════════════════════════════

print("=" * 72)
print(" NIA Co-Processor: Static Timing Analysis")
print(" Paper 1 (4:2 Compressor) vs Paper 2 (Carry-Select Adder)")
print("=" * 72)
print(f"\n Gate delay model: 180nm CMOS, 1 FO4 = {FO4_NS} ns")
print(f" NAND2={NAND2} XOR2={XOR2} MUX2={MUX2} INV={INV} FA={FA} (all in FO4)\n")

# ── Paper 1: compressor_adder_16 ─────────────────────────────────────────────
print("─" * 72)
print(" PAPER 1 — compressor_adder_16 (4:2 Compressor adder)")
print("─" * 72)

# Within one 4:2 compressor cell:
COX_delay   = AND2 + OR2          # majority(A,B,C): AB + BC + AC, then OR ≈ 3.0
D1_delay    = XOR2 + XOR2         # A^B^C  two-level XOR        ≈ 3.0
S_delay     = D1_delay + XOR2     # D1 ^ D ^ CIN                ≈ 4.5
CO_delay    = D1_delay + MUX2     # MUX(D1, D, CIN)             ≈ 4.5

print(f"\n  4:2 Compressor cell delays (FO4):")
print(f"    COX (majority gate)  : {COX_delay:.1f} FO4 = {ns(COX_delay):.3f} ns")
print(f"    D1  (A^B^C)          : {D1_delay:.1f} FO4 = {ns(D1_delay):.3f} ns")
print(f"    S   (D1^D^CIN)       : {S_delay:.1f}  FO4 = {ns(S_delay):.3f} ns")
print(f"    CO  (MUX)            : {CO_delay:.1f}  FO4 = {ns(CO_delay):.3f} ns")

# COX chain (16 columns): CIN[i+1] = COX[i], computed from A,B,C (not from CIN)
# Each column: COX from inputs takes COX_delay FO4
# But CIN of next column comes from COX of current — adds one wire delay (~0 FO4)
# The chain is: 16 × COX_delay? No — COX is independent of CIN!
# COX[0] = f(A[0],B[0],C[0]) — takes COX_delay from bit-0 inputs
# COX[1] = f(A[1],B[1],C[1]) — takes COX_delay from bit-1 inputs (not from COX[0]!)
# Wait: CIN[1] = COX[0]. CO[0] = D[1] (fed as D port). 
# S[1] = D1[1] ^ D[1] ^ CIN[1] = D1[1] ^ CO_prev ^ COX[0]
# So S[i] depends on COX[i-1] (which is independent of CIN chain above bit 0)
# Critical path for S[15]:
#   From A[0],B[0],C[0]: COX[0] = 3.0 FO4
#   S[1] = D1[1](3.0) ^ D[1] ^ COX[0](3.0) → 3.0 + 1.5 = 4.5 FO4 from bit-0 inputs
#   But bit-1 inputs also drive D1[1] directly (3.0 FO4 from bit-1)
#   So S[1] timing: max(D1[1](3.0), COX[0](3.0)) + XOR2 = 3.0 + 1.5 = 4.5 FO4
#   S[2] same structure: max(D1[2](3.0), COX[1](3.0)) + XOR2 = 4.5 FO4
#   All S[i] take the same path depth! (because COX[i] = f(A[i],B[i],C[i]) only)
# CONCLUSION: compressor_adder_16 critical path = S_delay = 4.5 FO4 (non-chained!)
# The COX → CIN connection does NOT extend the critical path because COX
# is computed from the SAME column inputs, not from previous column carry.

p1_adder_crit = S_delay   # all 16 bits computed in same depth
print(f"\n  Critical path: all 16-bit outputs in parallel (COX independent of CIN)")
print(f"  compressor_adder_16 critical path : {p1_adder_crit:.1f} FO4 = {ns(p1_adder_crit):.3f} ns")

# ── Paper 2: carry_select16 ───────────────────────────────────────────────────
print()
print("─" * 72)
print(" PAPER 2 — carry_select16 (4×carry_select4 chain)")
print("─" * 72)

# carry_select4: computes sum0 (cin=0) and sum1 (cin=1) in parallel,
# then MUX selects based on C_input.
# ripple_carry4 internal: 4 full adders in ripple chain
# Full adder: sum = a^b^cin (3-input XOR = 2×XOR2 = 3.0), cout = majority = 3.0
# Ripple_carry4 carry chain: 4 × cout propagation
#   cout[0]: 3.0 FO4
#   cout[1]: depends on cout[0] → 3.0 + NAND+INV per stage ≈ 3.0 + 2.0 = 5.0
#   Actually cout[i] = G[i] | (P[i] & C[i-1]):
#     G = AND2 = 1.5, P = XOR2 = 1.5, G|PC = OR(AND2, AND2) ≈ 3.5
#   Each stage: 1.5 (P) + 1.5 (AND) + 1.0 (OR) = 4.0 FO4 from previous carry
# Sum[3] of ripple4: P[3]^C[3] where C[3] takes 4 stages: 4 × ~2.0 carry step
#
# Simplified: standard 4-bit ripple carry
#   carry propagation: ~2.0 FO4 per bit (G/P + OR chain)
#   4-bit ripple carry delay: 4 × 2.0 = 8.0 FO4
#   sum[3] (worst): carry_4 + XOR = 8.0 + 1.5 = 9.5 FO4

rca4_carry = 4 * (AND2 + OR2) / 2   # simplified: ~2 FO4 per stage carry
rca4_sum   = rca4_carry + XOR2
csa4_delay = rca4_carry + MUX2      # carry_select4: ripple then MUX on carry
csa4_sum_delay = rca4_sum           # worst sum = last bit of ripple (before MUX stage)

print(f"\n  ripple_carry4 delays (FO4):")
print(f"    Carry propagation (4 bits): {rca4_carry:.1f} FO4 = {ns(rca4_carry):.3f} ns")
print(f"    Sum[3] worst case          : {rca4_sum:.1f}  FO4 = {ns(rca4_sum):.3f} ns")
print(f"\n  carry_select4 delays (FO4):")
print(f"    C_output (carry out)       : {csa4_delay:.1f}  FO4 = {ns(csa4_delay):.3f} ns  (ripple + MUX)")
print(f"    Result[3] (sum worst)      : {rca4_sum:.1f}  FO4 = {ns(rca4_sum):.3f} ns")

# carry_select16: 4 × carry_select4 blocks chained on carry
# Carry chain: each stage takes csa4_delay FO4 after previous C_output
# Total carry chain through 4 stages: 4 × csa4_delay
# Sum[15]: carry ripple through 3 stages + final ripple sum
n_stages  = 4
p2_carry_chain = n_stages * csa4_delay
p2_sum15  = (n_stages - 1) * csa4_delay + rca4_sum  # last stage sum
p2_adder_crit = p2_sum15

print(f"\n  carry_select16 (4 stages chained):")
print(f"    C_out (full chain)         : {p2_carry_chain:.1f} FO4 = {ns(p2_carry_chain):.3f} ns")
print(f"    SUM[15] critical path      : {p2_adder_crit:.1f} FO4 = {ns(p2_adder_crit):.3f} ns")

# ── Comparison ───────────────────────────────────────────────────────────────
print()
print("─" * 72)
print(" COMPARISON SUMMARY")
print("─" * 72)

# MAC cycle = adder + accumulator add (carry_select32 for both, same path)
# acc_out: add_accumulator uses direct Verilog '+' → synthesises to similar adder
# Assume 40-bit carry-select accumulator: ~10 × carry_select4 ≈ 10 × csa4_delay
acc40_crit = 10 * csa4_delay + rca4_sum  # conservative
FSM_OVERHEAD = 0.5  # FO4 for register setup+hold

p1_total = p1_adder_crit + acc40_crit + FSM_OVERHEAD
p2_total = p2_adder_crit + acc40_crit + FSM_OVERHEAD

p1_fmax = 1000.0 / ns(p1_total)   # MHz
p2_fmax = 1000.0 / ns(p2_total)   # MHz

print(f"\n  {'Metric':<38} {'Paper 1':>10} {'Paper 2':>10}")
print(f"  {'─'*38} {'─'*10} {'─'*10}")
print(f"  {'Multiplier adder critical path (FO4)':<38} {p1_adder_crit:>10.1f} {p2_adder_crit:>10.1f}")
print(f"  {'Multiplier adder critical path (ns)':<38} {ns(p1_adder_crit):>10.3f} {ns(p2_adder_crit):>10.3f}")
print(f"  {'Accumulator (40-bit) critical path (ns)':<38} {ns(acc40_crit):>10.3f} {ns(acc40_crit):>10.3f}")
print(f"  {'FSM + register overhead (ns)':<38} {ns(FSM_OVERHEAD):>10.3f} {ns(FSM_OVERHEAD):>10.3f}")
print(f"  {'─'*38} {'─'*10} {'─'*10}")
print(f"  {'Total combinational path (ns)':<38} {ns(p1_total):>10.3f} {ns(p2_total):>10.3f}")
print(f"  {'─'*38} {'─'*10} {'─'*10}")
print(f"  {'Estimated Fmax at 180nm (MHz)':<38} {p1_fmax:>10.0f} {p2_fmax:>10.0f}")
print(f"  {'Adder speedup (P1 over P2)':<38} {p2_adder_crit/p1_adder_crit:>10.2f}x {'':>10}")
print(f"  {'Overall Fmax gain (P1 over P2)':<38} {p1_fmax/p2_fmax:>10.2f}x {'':>10}")

# ── Cycle count (RTL simulation) ─────────────────────────────────────────────
print()
print("─" * 72)
print(" RTL SIMULATION CYCLE COUNTS (from vvp tb_NIA_comparison)")
print("─" * 72)
print("""
  Single MAC (16×16 multiply + accumulate):
    FSM states: LOAD(1) + RUN(1) + TEST×16 + ADD(1) + DONE(1) ≈ 20 cycles
    Simulated:  P1 = 39–54 cycles, P2 = 39–54 cycles (identical at RTL)
    Note: RTL simulation is cycle-accurate but not timing-accurate.
          Both designs use the SAME FSM, so cycle counts are equal.
          The ADDER only affects combinational delay WITHIN a clock cycle,
          not the number of clock cycles. Timing advantage is in Fmax.

  At Fmax (Paper 1 = {:.0f} MHz, Paper 2 = {:.0f} MHz):
    20-cycle MAC throughput:
      Paper 1: 20 / {:.0f}e6 = {:.1f} ns per MAC
      Paper 2: 20 / {:.0f}e6 = {:.1f} ns per MAC
    Throughput gain: {:.2f}x
""".format(p1_fmax, p2_fmax,
           p1_fmax, 20/p1_fmax*1000,
           p2_fmax, 20/p2_fmax*1000,
           (20/p2_fmax) / (20/p1_fmax)))

# ── Gate count estimate ───────────────────────────────────────────────────────
print("─" * 72)
print(" GATE COUNT ESTIMATE (NAND2-equivalent)")
print("─" * 72)

# compressor_adder_16: 16 × compressor_4_2 cells
# Each 4:2 cell: ~3 XOR2 + 2 AND2 + 1 OR2 + 1 MUX2 ≈ 3×3 + 2×1.5 + 1×1.5 + 1×2 = 18 NAND2-eq
p1_adder_gates = 16 * 18
# carry_select16: 4 × carry_select4; each carry_select4 has 2×ripple_carry4
# ripple_carry4: 4 full adders = 4×(3 XOR + 2 AND + 2 OR) ≈ 4×12 = 48 each
# carry_select4: 2×ripple(48) + 1×MUX4(8) ≈ 104 NAND2-eq
p2_adder_gates = 4 * 104

print(f"\n  compressor_adder_16 (Paper 1): ~{p1_adder_gates} NAND2-equivalent gates")
print(f"  carry_select16      (Paper 2): ~{p2_adder_gates} NAND2-equivalent gates")
print(f"  Area ratio (P2/P1)           : {p2_adder_gates/p1_adder_gates:.2f}x  "
      f"(Paper 1 is {'smaller' if p1_adder_gates < p2_adder_gates else 'larger'})")

# Full NIA (both use same accumulator, FSM, multiplier control)
common_gates = 500   # FSM + registers + accumulator (approximate)
p1_total_gates = p1_adder_gates + common_gates
p2_total_gates = p2_adder_gates + common_gates

print(f"\n  Full NIA (Paper 1 adder): ~{p1_total_gates} NAND2-eq gates")
print(f"  Full NIA (Paper 2 adder): ~{p2_total_gates} NAND2-eq gates")

# ── Conclusion ────────────────────────────────────────────────────────────────
print()
print("═" * 72)
print(" CONCLUSION")
print("═" * 72)
print(f"""
  Paper 1 (4:2 Compressor adder) achieves:
    • Shorter adder critical path: {ns(p1_adder_crit):.2f} ns vs {ns(p2_adder_crit):.2f} ns
    • Higher estimated Fmax:       {p1_fmax:.0f} MHz vs {p2_fmax:.0f} MHz
    • Smaller gate count in adder: ~{p1_adder_gates} vs ~{p2_adder_gates} NAND2-eq

  The key advantage (as described in Reddy et al. 2018, Paper 1):
    COX is computed INDEPENDENTLY of CIN, breaking the carry chain
    between columns. This allows all 16 SUM bits to resolve in the
    same combinational depth rather than chaining carry across 16 bits.

  Paper 2 (Carry-Select) chains 4 × carry_select4 blocks.
    Each block must wait for the previous carry to select the sum.
    4 MUX delays in series on the carry path extend the critical path.

  Recommendation: Use Paper 1 multiplier (MULTIPLIER_PAPER1) in the
  final NIA design. The adder is faster and more area-efficient.
""")
