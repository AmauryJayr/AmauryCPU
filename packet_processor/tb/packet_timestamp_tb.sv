`timescale 1ns/1ps

import packet_pkg::*;

module packet_timestamp_tb;

    logic clk;
    logic reset;

    logic valid_in;
    logic downstream_ready;
    packet_t data_in;

    logic upstream_ready;
    logic valid_out;

    packet_t data_out;
    packet_t expected_packet;

    int cycle;
    int errors;

    packet_timestamp dut (
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

        $dumpfile("packet_timestamp_tb.vcd");
        $dumpvars(0, packet_timestamp_tb);

        $display("================================");
        $display("PACKET TIMESTAMP TEST STARTED");
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
        //  testing normal packet with timestamp
        // --------------------------------------------------------
        data_in.id = 16'h1111;
        data_in.timestamp = 64'h0000000000000000;
        valid_in = 1;

        @(posedge clk);
        #1;
        cycle++;
        display_state();

        // --------------------------------------------------------
        //  Testing invalid packet with timestamp
        // --------------------------------------------------------

        @(negedge clk);
        data_in.id = 16'h2222;
        data_in.timestamp = 64'h0000000000000000;
        valid_in = 0;

        @(posedge clk);
        #1;
        cycle++;
        display_state();
        // --------------------------------------------------------
        //  testing downstream not ready normal packet with timestamp
        // --------------------------------------------------------
        @(negedge clk);
        data_in.id = 16'h3333;
        data_in.timestamp = 64'h0000000000000000;
        valid_in = 1;
        downstream_ready = 0;

        @(posedge clk);
        #1;
        cycle++;
        display_state();

        @(negedge clk);
        data_in.id = 16'h4444;
        valid_in = 1;

        @(posedge clk);
        #1;
        cycle++;
        display_state();

        @(negedge clk);
        downstream_ready = 1;
        data_in.id = 16'h5555;

        @(posedge clk);
        #1;
        cycle++;
        display_state();

        @(posedge clk);
        #1;
        cycle++;
        display_state();
        // --------------------------------------------------------
        // Finish
        // --------------------------------------------------------

        if (errors == 0) begin
            $display("");
            $display("====================================");
            $display("       PACKET TIMESTAMP TEST PASSED");
            $display("====================================");
        end
        else begin
            $display("");
            $display("====================================");
            $display("       PACKET TIMESTAMP TEST FAILED");
            $display("       Errors: %0d", errors);
            $display("====================================");
            $fatal(1);
        end

        $finish;
    end

    task automatic display_state();

        $display(
            "Cycle %0d| Timestamp %016h | valid_in=%b packet id=%h | upstream_ready=%b | valid_out=%b | downstream_ready=%b",
            cycle,
            data_out.timestamp,
            valid_in,
            data_out.id,
            upstream_ready,
            valid_out,
            downstream_ready
        );

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

endmodule