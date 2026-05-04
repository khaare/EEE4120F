///////////////////////////////////////////////////////////////////////////////
// 16-bit MAC Add-Accumulator Block
// 
// Input product: 32-bit (from 16-bit × 16-bit multiplication)
// Accumulator:   40-bit (32-bit product + 8 guard bits for multiple iterations)
// Data Format:   Q16.16 for product, Q24.16 for accumulator
///////////////////////////////////////////////////////////////////////////////

module add_accumulator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    input  wire [31:0] product_in,    // 32-bit product from multiplier
    input  wire        clear_acc,
    input  wire        saturate_en,
    output reg  [39:0] acc_out,       // 40-bit accumulator output
    output reg         overflow
);

    // Internal accumulator register (40 bits)
    reg  [39:0] acc;
    reg         overflow_reg;
    
    // Sign-extend product to 40 bits for addition
    wire [39:0] product_extended;
    assign product_extended = {{8{product_in[31]}}, product_in};
    
    // Sum with extra bit for overflow detection (41 bits)
    wire [40:0] sum;
    assign sum = {acc[39], acc} + {product_extended[39], product_extended};
    
    // Overflow detected when sign bits don't match
    wire overflow_detected;
    assign overflow_detected = (sum[40] != sum[39]);
    
    // Saturation values for 40-bit Q24.16 format
    localparam SAT_MAX = 40'h7FFFFFFFFF;  // Max positive
    localparam SAT_MIN = 40'h8000000000;  // Min negative
    
    // Combinational next state logic
    wire [39:0] next_acc;
    wire        next_overflow;
    
    assign next_acc = clear_acc ? 40'b0 :
                      (enable && saturate_en && overflow_detected) ? (sum[40] ? SAT_MIN : SAT_MAX) :
                      enable ? sum[39:0] :
                      acc;
                      
    assign next_overflow = clear_acc ? 1'b0 :
                           (enable && saturate_en && overflow_detected) ? 1'b1 :
                           enable ? overflow_detected :
                           1'b0;
    
    // Sequential update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc <= 40'b0;
            overflow_reg <= 1'b0;
            acc_out <= 40'b0;
        end else begin
            acc <= next_acc;
            overflow_reg <= next_overflow;
            acc_out <= next_acc;
            overflow <= next_overflow;
        end
    end

endmodule