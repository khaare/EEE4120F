module carry_select16 (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire         cin,
    output wire [15:0]  sum,
    output wire         cout
);
    wire [3:0] carry_mid;
    
    // Split into 4 groups of 4 bits each
    carry_select4 cs0 (.a(a[3:0]), .b(b[3:0]), .cin(cin),        .sum(sum[3:0]), .cout(carry_mid[0]));
    carry_select4 cs1 (.a(a[7:4]), .b(b[7:4]), .cin(carry_mid[0]), .sum(sum[7:4]), .cout(carry_mid[1]));
    carry_select4 cs2 (.a(a[11:8]), .b(b[11:8]), .cin(carry_mid[1]), .sum(sum[11:8]), .cout(carry_mid[2]));
    carry_select4 cs3 (.a(a[15:12]), .b(b[15:12]), .cin(carry_mid[2]), .sum(sum[15:12]), .cout(cout));
    
endmodule