`timescale 1ns / 1ps

module GPR_tb;

    reg         clk;
    reg         reg_write_en;
    reg  [2:0]  reg_write_dest;
    reg  [15:0] reg_write_data;
    reg  [2:0]  reg_read_addr_1;
    reg  [2:0]  reg_read_addr_2;
    wire [15:0] reg_read_data_1;
    wire [15:0] reg_read_data_2;

    GPR uut (
        .clk             (clk),
        .write    (reg_write_en),
        .address1 (reg_read_addr_1),
        .address2 (reg_read_addr_2),
        .writeDest  (reg_write_dest),
        .writeData  (reg_write_data),
        .readData1 (reg_read_data_1),
        .readData2 (reg_read_data_2)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("waves/gpr_tb.vcd");
        $dumpvars(0, GPR_tb);
    end

    integer fail_count;
    integer test_id;

    initial begin
        fail_count = 0;
        test_id    = 1;
    end

    task check16;
        input [15:0] got;
        input [15:0] expected;
        input [63:0] id;
        begin
            if (got !== expected) begin
                $display("FAIL [T%0d]: got = 0x%h, expected = 0x%h", id, got, expected);
                fail_count = fail_count + 1;
            end else
                $display("PASS [T%0d]: value = 0x%h", id, got);
        end
    endtask

    initial begin
        $display("=== GPR Testbench ===");

        reg_write_en    = 1'b0;
        reg_write_dest  = 3'd0;
        reg_write_data  = 16'd0;
        reg_read_addr_1 = 3'd0;
        reg_read_addr_2 = 3'd0;

        @(posedge clk); #1;

        $display("--- Test Group 1: Write and read back all 8 registers ---");

        reg_write_en = 1'b1;
        reg_write_dest = 3'd0; reg_write_data = 16'h0000; @(posedge clk); #1;
        reg_write_dest = 3'd1; reg_write_data = 16'hB001; @(posedge clk); #1;
        reg_write_dest = 3'd2; reg_write_data = 16'hC002; @(posedge clk); #1;
        reg_write_dest = 3'd3; reg_write_data = 16'hD003; @(posedge clk); #1;
        reg_write_dest = 3'd4; reg_write_data = 16'hE004; @(posedge clk); #1;
        reg_write_dest = 3'd5; reg_write_data = 16'hF005; @(posedge clk); #1;
        reg_write_dest = 3'd6; reg_write_data = 16'h1006; @(posedge clk); #1;
        reg_write_dest = 3'd7; reg_write_data = 16'h2007; @(posedge clk); #1;
        reg_write_en = 1'b0;

        reg_read_addr_1 = 3'd0; #2; check16(reg_read_data_1, 16'h0000, test_id); test_id = test_id + 1;
        reg_read_addr_1 = 3'd1; #2; check16(reg_read_data_1, 16'hB001, test_id); test_id = test_id + 1;
        reg_read_addr_1 = 3'd2; #2; check16(reg_read_data_1, 16'hC002, test_id); test_id = test_id + 1;
        reg_read_addr_1 = 3'd3; #2; check16(reg_read_data_1, 16'hD003, test_id); test_id = test_id + 1;
        reg_read_addr_1 = 3'd4; #2; check16(reg_read_data_1, 16'hE004, test_id); test_id = test_id + 1;
        reg_read_addr_1 = 3'd5; #2; check16(reg_read_data_1, 16'hF005, test_id); test_id = test_id + 1;
        reg_read_addr_1 = 3'd6; #2; check16(reg_read_data_1, 16'h1006, test_id); test_id = test_id + 1;
        reg_read_addr_1 = 3'd7; #2; check16(reg_read_data_1, 16'h2007, test_id); test_id = test_id + 1;

        $display("--- Test Group 2: Disabled write must not modify register ---");

        reg_write_en   = 1'b0;
        reg_write_dest = 3'd0;
        reg_write_data = 16'hDEAD;
        @(posedge clk); #1;

        reg_read_addr_1 = 3'd0; #2;
        check16(reg_read_data_1, 16'h0000, test_id); test_id = test_id + 1;

        $display("--- Test Group 3: Simultaneous dual-port read ---");

        reg_read_addr_1 = 3'd1;
        reg_read_addr_2 = 3'd3;
        #2;
        check16(reg_read_data_1, 16'hB001, test_id); test_id = test_id + 1;
        check16(reg_read_data_2, 16'hD003, test_id); test_id = test_id + 1;

        reg_read_addr_1 = 3'd5;
        reg_read_addr_2 = 3'd7;
        #2;
        check16(reg_read_data_1, 16'hF005, test_id); test_id = test_id + 1;
        check16(reg_read_data_2, 16'h2007, test_id); test_id = test_id + 1;

        $display("--- Test Group 4: Read address matches write address during write ---");

        reg_write_en    = 1'b1;
        reg_write_dest  = 3'd2;
        reg_write_data  = 16'hBEEF;
        reg_read_addr_1 = 3'd2;
        #2;
        $display("INFO [T%0d]: Read during write = 0x%h (old value before clock edge)",
                 test_id, reg_read_data_1);
        test_id = test_id + 1;

        @(posedge clk); #1;
        reg_write_en = 1'b0;
        #2;
        check16(reg_read_data_1, 16'hBEEF, test_id); test_id = test_id + 1;

        $display("");
        if (fail_count == 0)
            $display("=== ALL %0d TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d TESTS FAILED ===", fail_count, test_id - 1);

        $finish;
    end

endmodule