

import packet_pkg::*;
module packet_dotp #(
    parameter int WIDTH = 16
)( 
    input  logic clk,
    input  logic reset,

    input  logic valid_in,
    input packet_t data_in,
    input logic downstream_ready,

    output logic valid_out,
    output packet_t data_out,
    output logic upstream_ready
);

    logic [2*WIDTH-1:0] product0, product1;
    logic [2*WIDTH-1:0] product2, product3;

    logic [2*WIDTH:0] sum0, sum1;

    logic valid_stage1;
    logic valid_stage2;
    logic valid_stage3;

    packet_t data_reg_stage1;
    packet_t data_reg_stage2;
    packet_t data_reg_stage3;

    logic ready_reg_stage1;
    logic ready_reg_stage2;
    logic ready_reg_stage3;

    assign upstream_ready = (!valid_stage1 || ready_reg_stage1);//is stage 1 
    assign ready_reg_stage1 = (!valid_stage2 || ready_reg_stage2);//is stage 1 
    assign ready_reg_stage2 = (!valid_stage3 || ready_reg_stage3);//is stage 2
    assign ready_reg_stage3 = (downstream_ready);//is stage 3

    assign data_out = data_reg_stage3;
    assign valid_out = valid_stage3;



    always_ff @(posedge clk) begin
        if (reset) begin

            product0 <= '0;
            product1 <= '0;
            product2 <= '0;
            product3 <= '0;

            sum0 <= '0;
            sum1 <= '0;

            data_reg_stage2 <= '0;

            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;

        end else begin

                // Stage 1: multiplications
            if(upstream_ready) begin//Is the input valid and the module ready to accept it
                data_reg_stage1 <= data_in;
                valid_stage1 <= valid_in;
                product0 <= data_in.a0 * data_in.b0;
                product1 <= data_in.a1 * data_in.b1;
                product2 <= data_in.a2 * data_in.b2;
                product3 <= data_in.a3 * data_in.b3;
            end
            //stage 2
            if(ready_reg_stage1 && valid_stage1) begin//is the first stage valid and the second stage ready to accept it?
                if(!valid_in) begin
                    valid_stage1 <= 1'b0;
                end
                data_reg_stage2 <= data_reg_stage1;
                valid_stage2 <= 1'b1;
                sum0 <= product0 + product1;
                sum1 <= product2 + product3;

            end
            //stage 3
            if(ready_reg_stage2 && valid_stage2) begin
                if(!valid_stage1) begin
                    valid_stage2 <= 1'b0;
                end
                data_reg_stage3 <= data_reg_stage2;
                valid_stage3 <= 1'b1;
                data_reg_stage3.result <= sum0 + sum1;
            end
            //out
            if(ready_reg_stage3 && valid_stage3)begin
                if(!valid_stage2) begin
                    valid_stage3 <= 1'b0;
                end
            end

        end
    end

endmodule