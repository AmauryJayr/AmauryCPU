`timescale 1ns/1ps

module fifo_tb;

    localparam int DATA_WIDTH = 8;
    localparam int DEPTH = 4;

    logic clk, reset, wr_en, rd_en;
    logic [DATA_WIDTH-1:0] data_in;

    logic full, empty;
    logic [DATA_WIDTH-1:0] data_out;
    int errors;

    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
    .clk(clk),
        .reset(reset),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .data_in(data_in),
        .full(full),
        .empty(empty),
        .data_out(data_out)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("fifo.vcd");
        $dumpvars(0, fifo_tb);
        clk = 0;
        errors = 0;

        reset = 1;
        wr_en = 0;
        rd_en = 0;
        data_in = 0;

        #20;

        reset = 0;

        @(negedge clk);
        rd_en = 1;

        @(posedge clk);
        #1
        check_flags(1'b0, 1'b1, "FIFO empty after reset");
        rd_en = 0;

        @(negedge clk);
        wr_en = 1;
        data_in = 8'hAA;

        @(negedge clk);
        data_in = 8'hBB;

        @(negedge clk);
        data_in = 8'hCC;

        @(negedge clk);
        data_in = 8'hDD;

        @(negedge clk);
        data_in = 8'h11;//attempting overflow

        @(negedge clk);
        wr_en = 0;
        rd_en = 1;

        @(posedge clk);
        check_flags(1'b1, 1'b0, "FIFO full after four writes");
        #1 check_data(8'hAA);

        @(posedge clk);
        #1 check_data(8'hBB);

        @(posedge clk);
        #1 check_data(8'hCC);

        @(posedge clk);
        #1 check_data(8'hDD);
        check_flags(1'b0, 1'b1, "FIFO empty after four reads");

        @(negedge clk);
        wr_en = 1;
        rd_en = 0;
        data_in = 8'hEE;

        @(negedge clk);
        data_in = 8'hFF;
        rd_en = 1;

        @(posedge clk);
        #1 check_data(8'hEE);

        @(negedge clk);
        wr_en = 0;

        @(posedge clk);
        #1 check_data(8'hFF);

        @(negedge clk);
        rd_en = 0;
        check_flags(1'b0, 1'b1, "FIFO empty after wraparound reads");

        if (errors == 0) begin
            $display("TEST PASSED");
            $finish;
        end
        else begin
            $display("TEST FAILED: %0d error(s)", errors);
            $fatal(1);
        end
    end

    task automatic check_data(input logic [DATA_WIDTH-1:0] expected);
        if (data_out !== expected) begin
            $display("FAIL: expected data_out=%h, got %h", expected, data_out);
            errors++;
        end
        else begin
            $display("PASS: data_out=%h", data_out);
        end
    endtask

    task automatic check_flags(
        input logic expected_full,
        input logic expected_empty,
        input string description
    );
        if ((full !== expected_full) || (empty !== expected_empty)) begin
            $display(
                "FAIL: %s (expected full=%b empty=%b, got full=%b empty=%b)",
                description, expected_full, expected_empty, full, empty
            );
            errors++;
        end
        else begin
            $display("PASS: %s", description);
        end
    endtask

endmodule