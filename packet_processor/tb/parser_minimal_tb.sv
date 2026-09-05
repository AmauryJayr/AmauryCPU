`timescale 1ns/1ps

import packet_pkg::*;

module parser_minimal_tb;

    logic clk;
    logic reset;

    logic valid_in;
    logic downstream_ready;
    logic [63:0] data_in;

    logic upstream_ready;
    logic valid_out;

    packet_t data_out;
    packet_t expected_packet;

    int cycle;
    int errors;

    packet_parser dut (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_in),
        .downstream_ready(downstream_ready),
        .data_in(data_in),
        .upstream_ready(upstream_ready),
        .valid_out(valid_out),
        .data_out(data_out)
    );

    always #5 clk = ~clk;

    initial begin

        $dumpfile("parser_minimal_tb.vcd");
        $dumpvars(0, parser_minimal_tb);

        $display("================================");
        $display("PARSER MINIMAL TEST STARTED");
        $display("================================");

        clk = 0;
        reset = 1;
        valid_in = 0;
        downstream_ready = 1;
        data_in = 0;

        cycle = 0;
        errors = 0;

        #10;

        reset = 0;

        @(negedge clk);

        // --------------------------------------------------------
        // Send packet #1 - HEADER
        // --------------------------------------------------------

        valid_in = 1;
        data_in = 64'hDEADBEEFCAFEBABE;

        @(posedge clk);
        #1;

        cycle++;

        display_state();

        check_signal(
            upstream_ready,
            1'b1,
            "Parser should be ready during PAYLOAD_A"
        );

        check_signal(
            valid_out,
            1'b0,
            "Output should not be valid after PAYLOAD_A"
        );

        // --------------------------------------------------------
        // Send packet #1 - PAYLOAD A
        // --------------------------------------------------------

        @(negedge clk);

        data_in = 64'h0123456789ABCDEF;

        @(posedge clk);
        #1;

        cycle++;
        display_state();

        check_signal(
            upstream_ready,
            1'b1,
            "Parser should be ready during PAYLOAD_A"
        );

        check_signal(
            valid_out,
            1'b0,
            "Output should not be valid after PAYLOAD_A"
        );


        // --------------------------------------------------------
        // Send packet #1 - PAYLOAD B
        // --------------------------------------------------------

        @(negedge clk);

        data_in = 64'h0FEDCBA987654321;

        @(posedge clk);
        #1;

        cycle++;
        display_state();

        // The packet should now be complete.
        check_signal(
            valid_out,
            1'b1,
            "Output should be valid after complete packet"
        );

        check_signal(
            upstream_ready,
            1'b0,
            "Parser should stop accepting input while output is waiting"
        );


        // --------------------------------------------------------
        // BACKPRESSURE TEST
        //
        // Downstream is NOT ready.
        // Parser must hold the packet.
        // --------------------------------------------------------

        @(negedge clk);

        valid_in = 0;
        downstream_ready = 0;

        @(posedge clk);
        #1;

        cycle++;
        display_state();

        check_signal(
            valid_out,
            1'b1,
            "Parser must keep valid_out high during backpressure"
        );

        check_signal(
            upstream_ready,
            1'b0,
            "Parser must stop accepting input during backpressure"
        );

         // --------------------------------------------------------
        // Wait another cycle while downstream remains blocked
        // --------------------------------------------------------

        @(posedge clk);
        #1;

        cycle++;
        display_state();

        check_signal(
            valid_out,
            1'b1,
            "Parser must continue holding packet"
        );

        check_signal(
            upstream_ready,
            1'b0,
            "Parser must remain unable to accept input"
        );


        // --------------------------------------------------------
        // Release backpressure
        // --------------------------------------------------------

        @(negedge clk);

        downstream_ready = 1;

        @(posedge clk);
        #1;

        cycle++;
        display_state();

        check_signal(
            valid_out,
            1'b0,
            "Packet should be released after output handshake"
        );

        check_signal(
            upstream_ready,
            1'b1,
            "Parser should accept a new packet after output"
        );

       // HEADER
        expected_packet.message_type = 8'hDE;
        expected_packet.flags        = 8'hAD;
        expected_packet.id           = 16'hBEEF;
        expected_packet.length       = 32'hCAFEBABE;

        // PAYLOAD A
        expected_packet.a0 = 16'h0123;
        expected_packet.a1 = 16'h4567;
        expected_packet.a2 = 16'h89AB;
        expected_packet.a3 = 16'hCDEF;

        // PAYLOAD B
        expected_packet.b0 = 16'h0FED;
        expected_packet.b1 = 16'hCBA9;
        expected_packet.b2 = 16'h8765;
        expected_packet.b3 = 16'h4321;


        check_output(
            data_out,
            expected_packet
        );


        // --------------------------------------------------------
        // Send packet #2
        // --------------------------------------------------------

        @(negedge clk);

        valid_in = 1;
        data_in = 64'h1111222233334444;

        @(posedge clk);
        #1;

        cycle++;
        display_state();


        @(negedge clk);

        data_in = 64'h5555666677778888;

        @(posedge clk);
        #1;

        cycle++;
        display_state();


        @(negedge clk);

        data_in = 64'h9999AAAABBBBCCCC;

        @(posedge clk);
        #1;

        cycle++;
        display_state();

        check_signal(
            valid_out,
            1'b1,
            "Second packet should produce valid output"
        );

        expected_packet.message_type = 8'h11;
        expected_packet.flags = 8'h11;
        expected_packet.id = 16'h2222;
        expected_packet.length = 32'h33334444;
        expected_packet.a0 = 16'h5555;
        expected_packet.a1 = 16'h6666;
        expected_packet.a2 = 16'h7777;
        expected_packet.a3 = 16'h8888;
        expected_packet.b0 = 16'h9999;
        expected_packet.b1 = 16'hAAAA;
        expected_packet.b2 = 16'hBBBB;
        expected_packet.b3 = 16'hCCCC;

        $display("upstream_ready = %b", upstream_ready);
        $display("valid_out      = %b", valid_out);

        // --------------------------------------------------------
        // Finish
        // --------------------------------------------------------

        if (errors == 0) begin
            $display("");
            $display("====================================");
            $display("       PACKET PARSER TEST PASSED");
            $display("====================================");
        end
        else begin
            $display("");
            $display("====================================");
            $display("       PACKET PARSER TEST FAILED");
            $display("       Errors: %0d", errors);
            $display("====================================");
            $fatal(1);
        end

        $finish;

    end

    
    // ------------------------------------------------------------
    // Display current interface state
    // ------------------------------------------------------------

    task automatic display_state();

        $display(
            "Cycle %0d | valid_in=%b data_in=%h | upstream_ready=%b | valid_out=%b | downstream_ready=%b",
            cycle,
            valid_in,
            data_in,
            upstream_ready,
            valid_out,
            downstream_ready
        );

    endtask


    // ------------------------------------------------------------
    // Generic signal checker
    // ------------------------------------------------------------

    task automatic check_signal(
        input logic actual,
        input logic expected,
        input string description
    );

        if (actual !== expected) begin

            $display(
                "FAIL: %s | expected=%b got=%b",
                description,
                expected,
                actual
            );

            errors++;

        end
        else begin

            $display(
                "PASS: %s",
                description
            );

        end

    endtask

    task automatic check_output(
        input packet_t actual,
        input packet_t expected
    );

        if (actual !== expected) begin
            $display(
                "FAIL PACKET: expected=%h got=%h",
                expected,
                actual
            );
            errors++;
        end
        else begin
            $display("PASS: Packet contents match");
        end

    endtask

endmodule