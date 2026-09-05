import packet_pkg::*;
module dot_product_tb;

    logic clk;
    logic reset;

    logic valid_in;
    logic ready_in;
    packet_t data_in;

    logic ready_out;
    logic valid_out;

    packet_t data_out;
    packet_t expected_packet;

    int cycle;
    int errors;

    packet_dotp dut (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_in),
        .upstream_ready(ready_in),
        .data_in(data_in),
        .downstream_ready(ready_out),
        .valid_out(valid_out),
        .data_out(data_out)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        $display(
            "C=%0d | in: V=%b R=%b |\nS1: V=%b R=%b | \nS2: V=%b R=%b |\nS3: V=%b R=%b | \nout: V=%b R=%b | \nproducts=%h,%h,%h,%h | sums=%h,%h | result=%h\n",
            cycle,
            dut.valid_in,
            dut.upstream_ready,
            dut.valid_stage1,
            dut.ready_reg_stage1,
            dut.valid_stage2,
            dut.ready_reg_stage2,
            dut.valid_stage3,
            dut.ready_reg_stage3,
            dut.valid_out,
            dut.downstream_ready,
            dut.product0,
            dut.product1,
            dut.product2,
            dut.product3,
            dut.sum0,
            dut.sum1,
            dut.data_out.result
        );
    end

    initial begin

        $dumpfile("dot_product_tb.vcd");
        $dumpvars(0, dot_product_tb);

        $display("================================");
        $display("DOT PRODUCT TEST STARTED");
        $display("================================");

        clk = 0;
        reset = 1;
        valid_in = 0;
        ready_out = 0;
        data_in = '0;

        cycle = 0;
        errors = 0;

        #10;

        reset = 0;

        @(negedge clk);//request 1
        data_in.id = 16'h0001;
        data_in.a0 = 16'h0001;
        data_in.b0 = 16'h0001;
        data_in.a1 = 16'h0000;
        data_in.b1 = 16'h0000;
        data_in.a2 = 16'h0000;
        data_in.b2 = 16'h0000;
        data_in.a3 = 16'h0000;
        data_in.b3 = 16'h0000;

        valid_in = 1;
        //ready_out  = 1;

        @(posedge clk); //cycle 1
        #1;
        @(negedge clk);//request 2
        valid_in = 1;

        data_in.id = 16'h0002;
        data_in.a0 = 16'h0001;
        data_in.b0 = 16'h0002;
        data_in.a1 = 16'h0000;
        data_in.b1 = 16'h0000;
        data_in.a2 = 16'h0000;
        data_in.b2 = 16'h0000;
        data_in.a3 = 16'h0000;
        data_in.b3 = 16'h0000;

        @(posedge clk); //cycle 1
        #1;
        @(negedge clk);//request 3
        valid_in = 1;

        data_in.id = 16'h0003;
        data_in.a0 = 16'h0003;
        data_in.b0 = 16'h0001;
        data_in.a1 = 16'h0000;
        data_in.b1 = 16'h0000;
        data_in.a2 = 16'h0000;
        data_in.b2 = 16'h0000;
        data_in.a3 = 16'h0000;
        data_in.b3 = 16'h0000;

        @(posedge clk); //cycle 1
        #1;
        @(negedge clk);//request 4
        valid_in = 1;

        data_in.id = 16'h0004;
        data_in.a0 = 16'h0001;
        data_in.b0 = 16'h0004;
        data_in.a1 = 16'h0000;
        data_in.b1 = 16'h0000;
        data_in.a2 = 16'h0000;
        data_in.b2 = 16'h0000;
        data_in.a3 = 16'h0000;
        data_in.b3 = 16'h0000;
        @(negedge clk);
        valid_in = 0;
        
        repeat (3) begin
            @(posedge clk);
            #1;
            cycle++;
            //display_state();
        end
        @(negedge clk);
        ready_out = 1;
        $display("READY OUT");
        repeat (5) begin
            @(posedge clk);
            #1;
            cycle++;
            //display_state();
        end



        $finish;
    end

    task automatic display_state();

        $display(
            "Cycle %0d| valid_in=%b data message_type=%h data_flags=%h data_id=%h data_length=%h data_timestamp=%h| \n data_a0=%h data_a1=%h data_a2=%h data_a3=%h | data_b0=%h data_b1=%h data_b2=%h data_b3=%h | data_result=%h\nready_in=%b | valid_out=%b | ready_out=%b\n",
            cycle,
            valid_in,
            data_out.message_type,
            data_out.flags,
            data_out.id,
            data_out.length,
            data_out.timestamp,
            data_out.a0,
            data_out.a1,
            data_out.a2,
            data_out.a3,
            data_out.b0,
            data_out.b1,
            data_out.b2,
            data_out.b3,
            data_out.result,
            ready_in,
            valid_out,
            ready_out
        );

    endtask




endmodule