import packet_pkg::*;

module package_test;

    packet_t packet;

    initial begin

        packet = '0;

        packet.message_type = 8'hDE;
        packet.flags        = 8'hAD;
        packet.id           = 16'hBEEF;
        packet.length       = 32'hCAFEBABE;

        $display("PACKAGE TEST");
        $display("message_type = %h", packet.message_type);
        $display("flags        = %h", packet.flags);
        $display("id           = %h", packet.id);
        $display("length       = %h", packet.length);

        $finish;

    end

endmodule