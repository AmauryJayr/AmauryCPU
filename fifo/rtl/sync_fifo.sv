module fifo #(
    parameter int DATA_WIDTH = 8, 
    parameter int DEPTH = 16
)(
    input  logic                  clk,
    input  logic                  reset,
    input  logic                  wr_en,
    input  logic                  rd_en,
    input  logic [DATA_WIDTH-1:0] data_in,

    output logic                  full,
    output logic                  empty,
    output logic [DATA_WIDTH-1:0] data_out
);

    localparam int PTR_W = $clog2(DEPTH);
    localparam int CNT_WIDTH = $clog2(DEPTH + 1);

    logic [DATA_WIDTH-1:0] memory [0:DEPTH-1];
    logic [PTR_W - 1 : 0] wr_ptr, rd_ptr;
    
    logic [CNT_WIDTH-1:0] occupancy;

    assign empty = (occupancy == 0);
    assign full  = (occupancy == DEPTH);

    always_ff @( posedge clk ) begin

        if (reset) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            occupancy <= '0;
            data_out <= '0;
        end

        else begin

            if(rd_en) begin
                if(empty == 0) begin
                    data_out <= memory[rd_ptr];
                    if (rd_ptr == DEPTH - 1)
                        rd_ptr <= '0;
                    else
                        rd_ptr <= rd_ptr + 1'b1;
                end
            end

            if(wr_en)  begin
                if(full == 0) begin
                    memory[wr_ptr] <= data_in;
                    if( wr_ptr == DEPTH -1)
                        wr_ptr <= '0;
                    else
                        wr_ptr <= wr_ptr + 1'b1;
                    end
            end


            case ({wr_en && !full, rd_en && !empty})

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
    