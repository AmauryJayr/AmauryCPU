`timescale 1ns/1ps



//then test to see what happens if it is blocked

//then ill test to see what happens when one of them is droped and the downstream is not ready




import packet_pkg::*;

module packet_filter_tb;

    logic clk;
    logic reset;

    logic valid_in;
    logic downstream_ready;
    packet_t data_in;

    logic upstream_ready;
    logic valid_out;
    packet_t data_out;


    int cycle;
    int errors;

    packet_filter dut(
        .clk(clk),
        .reset(reset),
        .valid_in(valid_in),
        .upstream_ready(upstream_ready),
        .data_in(data_in),
        .valid_out(valid_out),
        .downstream_ready(downstream_ready),
        .data_out(data_out)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("packet_filter_tb.vcd");
        $dumpvars(0, packet_filter_tb);

        $display("================================");
        $display("PACKET FILTER TEST STARTED");
        $display("================================");

        clk = 0;
        reset = 1;
        valid_in = 0;
        downstream_ready = 1;

        data_in.message_type = 8'h00;
        data_in.flags = 8'h00;
        data_in.id = 16'h0000;
        data_in.length = 32'h00000000;

        data_in.a0 = 16'h0000;
        data_in.a1 = 16'h0000;
        data_in.a2 = 16'h0000;
        data_in.a3 = 16'h0000;

        data_in.b0 = 16'h0000;
        data_in.b1 = 16'h0000;
        data_in.b2 = 16'h0000;
        data_in.b3 = 16'h0000;

        #10;

        reset = 0;

//normal pass through TEST
        @(negedge clk);

        valid_in = 1;

        // HEADER
        data_in.message_type = 8'h01;
        data_in.flags        = 8'hAD;
        data_in.id           = 16'h1111;
        data_in.length       = 32'hCAFEBABE;

        // PAYLOAD A
        data_in.a0 = 16'h0123;
        data_in.a1 = 16'h4567;
        data_in.a2 = 16'h89AB;
        data_in.a3 = 16'hCDEF;

        // PAYLOAD B
        data_in.b0 = 16'h0FED;
        data_in.b1 = 16'hCBA9;
        data_in.b2 = 16'h8765;
        data_in.b3 = 16'h4321;

        @(posedge clk);
        #1

        cycle++;

        display_state();
        check_signal(valid_out, 1'b1, "Accepted packet should be valid");
        check_signal(data_out.id, 16'h1111, "Accepted packet ID should be 1111");


        //Downstream is blocked and a packet comes behind.
        @(negedge clk);
        downstream_ready = 1'b0;
        data_in.id= 16'h2222;
        data_in.message_type = 8'h00;

        @(posedge clk);
        #1
        cycle ++;
        display_state();

        check_signal(valid_out, 1'b1,
             "Held packet must remain valid while downstream is blocked");

        check_signal(data_out.id, 16'h1111,
             "Held packet must not be overwritten");


        @(negedge clk);
        downstream_ready = 1'b1;

        @(posedge clk);
        #1 
        cycle ++;
        display_state();

        check_signal(valid_out, 1'b0,
             "Output should be empty after held packet is consumed");

//Downstream is blocked and a packet comes behind but the packet already in is dropped
        @(negedge clk);
        downstream_ready = 1'b0;
        data_in.id= 16'h3333;
        data_in.message_type = 8'h01;

        @(posedge clk);
        #1
        cycle ++;
        display_state();

        check_signal(valid_out, 1'b1,
             "Dropped packet must remain valid while downstream is blocked");

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

    task automatic display_state();

        $display(
            "Cycle %0d | valid_in=%b packet id=%h | upstream_ready=%b | valid_out=%b | downstream_ready=%b",
            cycle,
            valid_in,
            data_in.id,
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