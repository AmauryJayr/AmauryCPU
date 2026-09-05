`timescale 1ns/1ps

import packet_pkg::*;

module minimal_tb;

    packet_t packet;

    initial begin
        $display("================================");
        $display("MINIMAL TESTBENCH STARTED");
        $display("================================");

        packet = '0;

        $display("message_type = %h", packet.message_type);
        $display("TEST COMPLETE");

        $finish;
    end

endmodule