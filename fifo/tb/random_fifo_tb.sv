`timescale 1ns/1ps

module fifo_tb;

    localparam int DATA_WIDTH = 8;
    localparam int DEPTH     = 4;

    // ------------------------------------------------------------
    // DUT inputs
    // ------------------------------------------------------------

    logic clk;
    logic reset;
    logic wr_en;
    logic rd_en;
    logic [DATA_WIDTH-1:0] data_in;

    // ------------------------------------------------------------
    // DUT outputs
    // ------------------------------------------------------------

    logic full;
    logic empty;
    logic [DATA_WIDTH-1:0] data_out;

    // ------------------------------------------------------------
    // Testbench state
    // ------------------------------------------------------------

    int errors;

    // Reference FIFO
    logic [DATA_WIDTH-1:0] expected_queue[$];

    // Result of the reference model
    logic read_valid;
    logic [DATA_WIDTH-1:0] expected_data;

    // ------------------------------------------------------------
    // Device Under Test
    // ------------------------------------------------------------

    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk      (clk),
        .reset    (reset),
        .wr_en    (wr_en),
        .rd_en    (rd_en),
        .data_in  (data_in),
        .full     (full),
        .empty    (empty),
        .data_out (data_out)
    );

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Main test
    // ------------------------------------------------------------

    initial begin

        $dumpfile("fifo.vcd");
        $dumpvars(0, fifo_tb);

        // Initial values
        clk     = 0;
        errors  = 0;

        reset   = 1;
        wr_en   = 0;
        rd_en   = 0;
        data_in = 0;

        // Reset FIFO
        #20;
        reset = 0;

        // --------------------------------------------------------
        // Randomized test
        // --------------------------------------------------------

        for (int i = 0; i < 10000; i++) begin

            // Drive inputs away from the DUT's sampling edge
            @(negedge clk);

            wr_en   = $urandom_range(0, 1);
            rd_en   = $urandom_range(0, 1);
            data_in = $urandom_range(8'h00, 8'hFF);

            // Predict what the FIFO should do
            model_transaction(
                wr_en,
                rd_en,
                data_in,
                read_valid,
                expected_data
            );

            // DUT processes the transaction
            @(posedge clk);

            // Allow nonblocking assignments in the DUT to complete
            #1;

            // If a read was valid, compare DUT output
            if (read_valid) begin
                check_data(expected_data);
            end

            // Check full/empty flags
            check_flags(
                expected_queue.size() == DEPTH,
                expected_queue.size() == 0,
                "Randomized FIFO flags"
            );

        end

        // --------------------------------------------------------
        // Test result
        // --------------------------------------------------------

        if (errors == 0) begin
            $display("");
            $display("================================");
            $display("       TEST PASSED");
            $display("================================");
            $display("");

            $finish;
        end
        else begin
            $display("");
            $display("================================");
            $display("       TEST FAILED");
            $display("       %0d error(s)", errors);
            $display("================================");
            $display("");

            $fatal(1);
        end

    end

    // ------------------------------------------------------------
    // Check data output
    // ------------------------------------------------------------

    task automatic check_data(
        input logic [DATA_WIDTH-1:0] expected
    );

        if (data_out !== expected) begin

            $display(
                "FAIL: expected data_out=%h, got %h",
                expected,
                data_out
            );

            errors++;

        end
        else begin

            $display(
                "PASS: data_out=%h",
                data_out
            );

        end

    endtask

    // ------------------------------------------------------------
    // Check FIFO flags
    // ------------------------------------------------------------

    task automatic check_flags(
        input logic expected_full,
        input logic expected_empty,
        input string description
    );

        if ((full !== expected_full) ||
            (empty !== expected_empty)) begin

            $display(
                "FAIL: %s (expected full=%b empty=%b, got full=%b empty=%b)",
                description,
                expected_full,
                expected_empty,
                full,
                empty
            );

            errors++;

        end

    endtask

    // ------------------------------------------------------------
    // Reference FIFO model
    // ------------------------------------------------------------

    task automatic model_transaction(

        input logic wr,
        input logic rd,

        input logic [DATA_WIDTH-1:0] write_data,

        output logic read_valid,
        output logic [DATA_WIDTH-1:0] expected_read

    );

        logic write_valid;

        // Determine whether operations are valid
        // BEFORE changing the reference queue.

        read_valid  = rd &&
                      (expected_queue.size() > 0);

        write_valid = wr &&
                      (expected_queue.size() < DEPTH);

        expected_read = '0;

        // Read oldest element
        if (read_valid) begin
            expected_read = expected_queue.pop_front();
        end

        // Write new element
        if (write_valid) begin
            expected_queue.push_back(write_data);
        end

    endtask

endmodule