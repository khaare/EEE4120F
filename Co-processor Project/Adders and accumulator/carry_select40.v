module carry_select40 (
    input  wire [39:0] a,
    input  wire [39:0] b,
    input  wire         cin,
    output wire [39:0]  sum,
    output wire         cout
);
    wire [9:0] carry_mid;
    
    // Split into 10 groups of 4 bits each
    carry_select4 cs0  (.a(a[3:0]),   .b(b[3:0]),   .cin(cin),           .sum(sum[3:0]),   .cout(carry_mid[0]));
    carry_select4 cs1  (.a(a[7:4]),   .b(b[7:4]),   .cin(carry_mid[0]),  .sum(sum[7:4]),   .cout(carry_mid[1]));
    carry_select4 cs2  (.a(a[11:8]),  .b(b[11:8]),  .cin(carry_mid[1]),  .sum(sum[11:8]),  .cout(carry_mid[2]));
    carry_select4 cs3  (.a(a[15:12]), .b(b[15:12]), .cin(carry_mid[2]),  .sum(sum[15:12]), .cout(carry_mid[3]));
    carry_select4 cs4  (.a(a[19:16]), .b(b[19:16]), .cin(carry_mid[3]),  .sum(sum[19:16]), .cout(carry_mid[4]));
    carry_select4 cs5  (.a(a[23:20]), .b(b[23:20]), .cin(carry_mid[4]),  .sum(sum[23:20]), .cout(carry_mid[5]));
    carry_select4 cs6  (.a(a[27:24]), .b(b[27:24]), .cin(carry_mid[5]),  .sum(sum[27:24]), .cout(carry_mid[6]));
    carry_select4 cs7  (.a(a[31:28]), .b(b[31:28]), .cin(carry_mid[6]),  .sum(sum[31:28]), .cout(carry_mid[7]));
    carry_select4 cs8  (.a(a[35:32]), .b(b[35:32]), .cin(carry_mid[7]),  .sum(sum[35:32]), .cout(carry_mid[8]));
    carry_select4 cs9  (.a(a[39:36]), .b(b[39:36]), .cin(carry_mid[8]),  .sum(sum[39:36]), .cout(cout));
    
endmodule