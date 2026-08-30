`timescale 1ns/1ps

module pipelined_datapath_tb;

    localparam int WIDTH = 16;

    logic clk;
    logic reset;
    logic valid_in;

    logic [WIDTH-1:0] a0, a1, a2, a3;
    logic [WIDTH-1:0] b0, b1, b2, b3;

    logic valid_out;
    logic [2*WIDTH+1:0] result;

    dot_product #(
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_in),
        .a0(a0),
        .a1(a1),
        .a2(a2),
        .a3(a3),
        .b0(b0),
        .b1(b1),
        .b2(b2),
        .b3(b3),
        .valid_out(valid_out),
        .result(result)
    );

    always #5 clk = ~clk;

    initial begin

        $dumpfile("pipelined_datapath.vcd");
        $dumpvars(0, pipelined_datapath_tb);

        clk = 0;

        // Reset
        reset = 1;
        valid_in = 0;

        a0 = 0;
        a1 = 0;
        a2 = 0;
        a3 = 0;

        b0 = 0;
        b1 = 0;
        b2 = 0;
        b3 = 0;

        #20;

        reset = 0;

       // ------------------------------------------------
        // Back-to-back transactions
        // ------------------------------------------------

        @(negedge clk);

        // Transaction A
        valid_in = 1;

        a0 = 1;
        a1 = 2;
        a2 = 3;
        a3 = 4;

        b0 = 5;
        b1 = 6;
        b2 = 7;
        b3 = 8;


        // Transaction B
        @(negedge clk);

        a0 = 2;
        a1 = 3;
        a2 = 4;
        a3 = 5;

        b0 = 1;
        b1 = 2;
        b2 = 3;
        b3 = 4;


        // Transaction C
        @(negedge clk);

        a0 = 10;
        a1 = 20;
        a2 = 30;
        a3 = 40;

        b0 = 1;
        b1 = 1;
        b2 = 1;
        b3 = 1;


        // Transaction D
        @(negedge clk);

        a0 = 5;
        a1 = 5;
        a2 = 5;
        a3 = 5;

        b0 = 5;
        b1 = 5;
        b2 = 5;
        b3 = 5;
        #1;

        if (valid_out !== 1'b1 || result !== 34'd70) begin
            $display("FAIL: expected A = 70, got %0d", result);
            $fatal(1);
        end

        $display("PASS: A = %0d", result);


        @(posedge clk);
        #1;
        valid_in = 0;

        if (valid_out !== 1'b1 || result !== 34'd40) begin
            $display("FAIL: expected B = 40, got %0d", result);
            $fatal(1);
        end

        $display("PASS: B = %0d", result);


        @(posedge clk);
        #1;

        if (valid_out !== 1'b1 || result !== 34'd100) begin
            $display("FAIL: expected C = 100, got %0d", result);
            $fatal(1);
        end

        $display("PASS: C = %0d", result);


        @(posedge clk);
        #1;

        if (valid_out !== 1'b1 || result !== 34'd100) begin
            $display("FAIL: expected D = 100, got %0d", result);
            $fatal(1);
        end

        $display("PASS: D = %0d", result);

        @(posedge clk);
        #1;

        if (valid_out !== 1'b0) begin
            $display("FAIL: valid_out should be 0 after pipeline drains");
            $fatal(1);
        end

        $display("PASS: pipeline drained correctly");
        // ------------------------------------------------
        // Stop sending valid transactions
        // ------------------------------------------------

        @(negedge clk);
        valid_in = 0;

        @(posedge clk);
        #1;

        $display("Test completed.");

        $finish;

    end

endmodule