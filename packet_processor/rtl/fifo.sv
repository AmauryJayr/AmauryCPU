import packet_pkg::*;
module fifo #(
    parameter int DATA_WIDTH = 8, 
    parameter int DEPTH = 16
)(
    input logic clk,
    input logic reset,

    input  logic                  valid_in,
    input  logic                  ready_out,
    input  packet_t               data_in,

    output logic                  valid_out,
    output logic                  ready_in,
    output packet_t               data_out
);

    localparam int PTR_W = $clog2(DEPTH);
    localparam int CNT_WIDTH = $clog2(DEPTH + 1);

    packet_t memory [0:DEPTH-1];
    logic [PTR_W - 1 : 0] wr_ptr, rd_ptr;
    
    logic [CNT_WIDTH-1:0] occupancy;

    assign ready_in = !(occupancy == DEPTH);
    assign valid_out = (occupancy != 0);

    logic wr_en, rd_en;

    assign wr_en = valid_in && ready_in;
    assign rd_en = valid_out && ready_out;

    assign data_out = memory[rd_ptr]; 

    always_ff @( posedge clk ) begin

        if (reset) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            occupancy <= '0;
        end

        else begin

            if(rd_en) begin
                //data_out <= memory[rd_ptr];
                if (rd_ptr == DEPTH - 1)
                    rd_ptr <= '0;
                else
                    rd_ptr <= rd_ptr + 1'b1;
            end

            if(wr_en)  begin
                memory[wr_ptr] <= data_in;
                if( wr_ptr == DEPTH -1)
                    wr_ptr <= '0;
                else
                    wr_ptr <= wr_ptr + 1'b1;
            end


            case ({wr_en, rd_en})

                2'b10:
                    occupancy <= occupancy + 1'b1;
                2'b01:
                    occupancy <= occupancy - 1'b1;
                default:
                    occupancy <= occupancy;
            endcase

        end
    end

endmodule
    