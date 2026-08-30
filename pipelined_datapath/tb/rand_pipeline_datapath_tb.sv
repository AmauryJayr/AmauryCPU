`timescale 1ns/1ps

module pipelined_datapath_tb;

    localparam int WIDTH = 16;
    localparam int RESULT_WIDTH = 2*WIDTH + 2;

    logic clk;
    logic reset;
    logic valid_in;

    logic [WIDTH-1:0] a0, a1, a2, a3;
    logic [WIDTH-1:0] b0, b1, b2, b3;

    logic valid_out;
    logic [RESULT_WIDTH-1:0] result;

    int errors;

    logic expected_valid_out [3:0];
    logic [RESULT_WIDTH-1:0] expected_result [3:0];

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
        errors = 0;

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

        expected_valid_out[0] = 0;
        expected_valid_out[1] = 0;
        expected_valid_out[2] = 0;
        expected_valid_out[3] = 0;
        expected_result[0] = 0;
        expected_result[1] = 0;
        expected_result[2] = 0;
        expected_result[3] = 0;

        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        #20;
        reset = 0;

        // --------------------------------------------------------
        // Randomized test
        // --------------------------------------------------------

        for (int i = 0; i < 10000; i++) begin

            @(negedge clk);

            valid_in = $urandom_range(0, 1);

            if (valid_in) begin

                a0 = $urandom_range(0, 65535);
                a1 = $urandom_range(0, 65535);
                a2 = $urandom_range(0, 65535);
                a3 = $urandom_range(0, 65535);

                b0 = $urandom_range(0, 65535);
                b1 = $urandom_range(0, 65535);
                b2 = $urandom_range(0, 65535);
                b3 = $urandom_range(0, 65535);

                expected_result[0] =
                      (a0 * b0)
                    + (a1 * b1)
                    + (a2 * b2)
                    + (a3 * b3);

                expected_valid_out[0] = 1'b1;

            end
            else begin

                expected_valid_out[0] = 1'b0;

            end

            // Shift reference model

            expected_result[3] = expected_result[2];
            expected_valid_out[3] = expected_valid_out[2];

            expected_result[2] = expected_result[1];
            expected_valid_out[2] = expected_valid_out[1];

            expected_result[1] = expected_result[0];
            expected_valid_out[1] = expected_valid_out[0];


            // Let DUT process transaction
            @(posedge clk);
            #1;

            // Check valid
            if (valid_out !== expected_valid_out[3]) begin

                $display(
                    "FAIL transaction %0d: valid expected=%b got=%b",
                    i,
                    expected_valid_out[3],
                    valid_out
                );

                errors++;

            end

            // Check data only when valid
            if (valid_out) begin

                if (result !== expected_result[3]) begin

                    $display(
                        "FAIL transaction %0d: result expected=%0d got=%0d",
                        i,
                        expected_result[3],
                        result
                    );

                    errors++;

                end

            end

        end

        // --------------------------------------------------------
        // Flush pipeline
        // --------------------------------------------------------

        valid_in = 0;

        repeat (2) begin

            @(posedge clk);
            #1;

            expected_result[3] = expected_result[2];
            expected_valid_out[3] = expected_valid_out[2];

            expected_result[2] = expected_result[1];
            expected_valid_out[2] = expected_valid_out[1];

            expected_result[1] = expected_result[0];
            expected_valid_out[1] = expected_valid_out[0];

            expected_valid_out[0] = 0;

            if (valid_out !== expected_valid_out[3]) begin

                $display(
                    "FAIL during flush: valid expected=%b got=%b",
                    expected_valid_out[3],
                    valid_out
                );

                errors++;

            end

            if (valid_out && result !== expected_result[3]) begin

                $display(
                    "FAIL during flush: result expected=%0d got=%0d",
                    expected_result[3],
                    result
                );

                errors++;

            end

        end

        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------

        if (errors == 0) begin

            $display("");
            $display("==============================");
            $display("       TEST PASSED");
            $display("==============================");
            $display("");

        end
        else begin

            $display("");
            $display("==============================");
            $display("       TEST FAILED");
            $display("       %0d errors", errors);
            $display("==============================");
            $display("");

            $fatal(1);

        end

        $finish;

    end

endmodule