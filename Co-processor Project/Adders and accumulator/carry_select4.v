module carry_select4 (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire        cin,
    output wire [3:0]  sum,
    output wire        cout
);
    wire [3:0] sum0, sum1;
    wire       cout0, cout1;
    
    ripple_carry4 rca0 (  // Still need ripple_carry4 for 4-bit groups
        .a   (a),
        .b   (b),
        .cin (1'b0),
        .sum (sum0),
        .cout(cout0)
    );
    
    ripple_carry4 rca1 (
        .a   (a),
        .b   (b),
        .cin (1'b1),
        .sum (sum1),
        .cout(cout1)
    );
    
    assign sum = cin ? sum1 : sum0;
    assign cout = cin ? cout1 : cout0;
    
endmodule