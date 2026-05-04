module register40 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        load,
    input  wire [39:0] d,
    output reg  [39:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 40'b0;
        else if (load)
            q <= d;
    end
endmodule