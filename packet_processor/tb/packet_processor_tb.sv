`timescale 1ns/1ps
//Things i have tested
// 1. one request goes through
// 2. multiple requests go through
// 3. multiple requests go through with some being dropped
// 4. Block the ready_out and let three requests build up
module packet_processor_tb;

    localparam int NUM_PACKETS = 1000;

    logic clk;
    logic reset;

    logic valid_in;
    logic ready_in;
    logic [63:0] data_in;

    logic ready_out;
    logic valid_out;
    packet_t data_out;

    //scoreboard
    localparam int SCOREBOARD_DEPTH = 2048;

    packet_t expected_queue [0:SCOREBOARD_DEPTH-1];

    int sb_head;
    int sb_tail;
    int sb_count;

    int packets_sent;
    int packets_expected;
    int packets_received;
    int packets_dropped;
    int errors;

    task automatic scoreboard_push(input packet_t packet);
        begin
            if (sb_count >= SCOREBOARD_DEPTH) begin
                $display("ERROR: Scoreboard overflow");
                errors++;
            end
            else begin
                expected_queue[sb_tail] = packet;

                if (sb_tail == SCOREBOARD_DEPTH-1)
                    sb_tail = 0;
                else
                    sb_tail++;

                sb_count++;
            end
        end
    endtask

    task automatic scoreboard_pop(output packet_t packet);
        begin
            if (sb_count == 0) begin
                $display("ERROR: Scoreboard underflow");
                errors++;
                packet = '0;
            end
            else begin
                packet = expected_queue[sb_head];

                if (sb_head == SCOREBOARD_DEPTH-1)
                    sb_head = 0;
                else
                    sb_head++;

                sb_count--;
            end
        end
    endtask


    packet_processor dut (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_in),
        .ready_in(ready_in),
        .data_in(data_in),
        .ready_out(ready_out),
        .valid_out(valid_out),
        .data_out(data_out)
    );

    always #5 clk = ~clk;

    packet_t expected;

    always @(posedge clk) begin
        if (!reset && valid_out && ready_out) begin

            scoreboard_pop(expected);

            if (data_out.message_type !== expected.message_type ||
                data_out.flags        !== expected.flags        ||
                data_out.id           !== expected.id           ||
                data_out.length       !== expected.length       ||
                data_out.a0           !== expected.a0            ||
                data_out.a1           !== expected.a1            ||
                data_out.a2           !== expected.a2            ||
                data_out.a3           !== expected.a3            ||
                data_out.b0           !== expected.b0            ||
                data_out.b1           !== expected.b1            ||
                data_out.b2           !== expected.b2            ||
                data_out.b3           !== expected.b3            ||
                data_out.result       !== expected.result) begin

                $display("ERROR: Packet mismatch");
                $display("Expected ID = %h", expected.id);
                $display("Actual ID   = %h", data_out.id);

                errors++;
            end
            else begin
                packets_received++;
            end
        end
    end


    //send one packet

    task automatic send_packet(
        input logic [7:0]  message_type,
        input logic [7:0]  flags,
        input logic [15:0] id,
        input logic [31:0] length,

        input logic [15:0] a0,
        input logic [15:0] a1,
        input logic [15:0] a2,
        input logic [15:0] a3,

        input logic [15:0] b0,
        input logic [15:0] b1,
        input logic [15:0] b2,
        input logic [15:0] b3
    );
        packet_t expected;

        expected.message_type = message_type;
        expected.flags        = flags;
        expected.id           = id;
        expected.length       = length;

        expected.a0 = a0;
        expected.a1 = a1;
        expected.a2 = a2;
        expected.a3 = a3;

        expected.b0 = b0;
        expected.b1 = b1;
        expected.b2 = b2;
        expected.b3 = b3;

        expected.result =
              a0 * b0
            + a1 * b1
            + a2 * b2
            + a3 * b3;

        if (message_type == 8'h01) begin
            scoreboard_push(expected);
                packets_expected++;
            end
            else begin
                packets_dropped++;
            end
        
        //header 
        @(negedge clk);

        data_in = {
            message_type,
            flags,
            id,
            length
        };

        valid_in = 1'b1;

        while (1) begin

        @(posedge clk);

        if (ready_in)
            break;
        end
        //payload a

        @(negedge clk);

        data_in = {
            a0,
            a1,
            a2,
            a3
        };

        while (1) begin

            @(posedge clk);
            if (ready_in)
                break;
        end


        @(negedge clk);

        data_in = {
            b0,
            b1,
            b2,
            b3
        };

        while (1) begin
            @(posedge clk);
            if (ready_in)
                break;
        end

        // Stop presenting this packet.

        @(negedge clk);

        valid_in = 1'b0;
        data_in  = '0;

        packets_sent++;
    endtask

    //generate one random packet
    task automatic send_random_packet(
        input int packet_number
    );

        logic [7:0]  message_type;
        logic [7:0]  flags;
        logic [15:0] id;
        logic [31:0] length;

        logic [15:0] a0, a1, a2, a3;
        logic [15:0] b0, b1, b2, b3;

        // --------------------------------------------------------
        // Random packet
        // --------------------------------------------------------

        // Mostly accepted packets, with some rejected packets.
        if ($urandom_range(0, 4) == 0)
            message_type = 8'h00;
        else
            message_type = 8'h01;

        flags  = $urandom_range(0, 255);
        id     = packet_number;
        length = 32'd24;

        a0 = $urandom_range(0, 100);
        a1 = $urandom_range(0, 100);
        a2 = $urandom_range(0, 100);
        a3 = $urandom_range(0, 100);

        b0 = $urandom_range(0, 100);
        b1 = $urandom_range(0, 100);
        b2 = $urandom_range(0, 100);
        b3 = $urandom_range(0, 100);

        send_packet(
            message_type,
            flags,
            id,
            length,

            a0, a1, a2, a3,
            b0, b1, b2, b3
        );

    endtask

    //randomize output back pressure(changing ready_out)

    always @(negedge clk) begin
        if(!reset) begin
            //70% ready , 30% blocked
            if($urandom_range(0,9) < 7)
                ready_out <= 1'b1;
            else
                ready_out <= 1'b0;
        end
    end

    initial begin

        $dumpfile("packet_processor_tb.vcd");
        $dumpvars(0, packet_processor_tb);

        $display("================================");
        $display("PACKET PROCESSOR TEST STARTED");
        $display("================================");

        clk = 1'b0;

        reset = 1'b1;

        valid_in = 1'b0;
        data_in  = '0;

        ready_out = 1'b0;

        packets_sent     = 0;
        packets_expected = 0;
        packets_received = 0;
        packets_dropped  = 0;
        errors           = 0;
//send random packet test
        repeat (3)
            @(posedge clk);

            reset = 1'b0;

        for (int i = 0; i <NUM_PACKETS; i++) begin
            
            send_random_packet(i);
        end

        //stop

        @(negedge clk);

        valid_in = 1'b0;

        //drain the pipeline

        ready_out = 1'b1;

        repeat (200)
            @(posedge clk);

        //final scoreboard

        $display("test complete");
        $display("Packets sent:      %0d", packets_sent);
        $display("Packets accepted:  %0d", packets_expected);
        $display("Packets dropped:   %0d", packets_dropped);
        $display("Packets received:  %0d", packets_received);
        $display("Packets remaining: %0d", sb_count);
        $display("Errors:            %0d", errors);

        $display("");

        if (sb_count != 0) begin
            $display("ERROR: Scoreboard still contains packets!");
            errors++;
        end

        if (packets_received != packets_expected) begin
            $display(
                "ERROR: Expected %0d outputs, received %0d!",
                packets_expected,
                packets_received
            );
            errors++;
        end

          if (errors == 0) begin

            $display("==============================================");
            $display("             *** TEST PASSED ***");
            $display("==============================================");

        end
        else begin

            $display("==============================================");
            $display("             *** TEST FAILED ***");
            $display("==============================================");

        end

       
        $finish;
    end

endmodule