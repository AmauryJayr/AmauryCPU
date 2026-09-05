import packet_pkg::*;

module packet_timestamp #(
    parameter int WIDTH = 64
    )(
    input logic clk,
    input logic reset,
    input logic valid_in,
    input packet_t data_in,
    input logic downstream_ready,
    output logic upstream_ready,
    output packet_t data_out,
    output logic valid_out
);
    packet_t data_reg;
    logic valid_reg;

    assign valid_out = valid_reg;
    assign data_out = data_reg;

    assign upstream_ready = !valid_reg || downstream_ready;
    logic [WIDTH-1:0] counter;


    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= '0;
            valid_reg <= 1'b0;
        end else begin
            counter <= counter + 1;
            if (valid_in && upstream_ready) begin
                data_reg <= data_in;
                data_reg.timestamp <= counter;
                valid_reg <= 1'b1;
            end 
            else if(valid_reg && downstream_ready) begin
                valid_reg <= 1'b0;
            end
        end
    end
endmodule