
// TYPE:0x01 -> accept
// TYPE:0x02 -> reject  
import packet_pkg::*;
//make sure that while the ready signal is low then goes high, that we dont erase the last valid packet
module packet_filter #(
    parameter int WIDTH = 16
)(
    input logic clk,
    input logic reset,
    input logic valid_in,
    output logic upstream_ready,//ready in is the ready signal of this stage
    input packet_t data_in,
    output logic valid_out,
    input logic downstream_ready,//ready of the next stage
    output packet_t data_out
);

    packet_t data_reg;
    logic valid_reg;

    assign valid_out = valid_reg;
    assign data_out = data_reg;

    assign upstream_ready = !valid_reg || downstream_ready;

    always_ff @( posedge clk) begin
        if (reset) begin
            data_reg <= '0;
            valid_reg <= 1'b0;
        end else begin
            if(upstream_ready && valid_in) begin//a proper packet comes in but the filter takes it out
                if(data_in.message_type == 8'h01) begin
                    data_reg <= data_in;
                    valid_reg <= 1'b1;
                end
                else begin
                    valid_reg <= 1'b0;
                end
            end

            else if(downstream_ready && valid_reg) begin
                valid_reg <= 1'b0;
            end
        end
    end


endmodule