module dot_product #(
    parameter int WIDTH = 16
)( 
    input  logic clk,
    input  logic reset,
    input  logic valid_in,

    input logic [WIDTH-1:0] a0,
    input logic [WIDTH-1:0] a1,
    input logic [WIDTH-1:0] a2,
    input logic [WIDTH-1:0] a3,

    input logic [WIDTH-1:0] b0,
    input logic [WIDTH-1:0] b1,
    input logic [WIDTH-1:0] b2,
    input logic [WIDTH-1:0] b3,

    output logic valid_out,
    output logic [2*WIDTH+1:0] result
);

    logic [2*WIDTH-1:0] product0, product1;
    logic [2*WIDTH-1:0] product2, product3;

    logic [2*WIDTH:0] sum0, sum1;

    logic valid_stage1;
    logic valid_stage2;

    always_ff @(posedge clk) begin
        if (reset) begin

            product0 <= '0;
            product1 <= '0;
            product2 <= '0;
            product3 <= '0;

            sum0 <= '0;
            sum1 <= '0;

            result <= '0;

            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_out    <= 1'b0;

        end else begin

            // Stage 1: multiplications
            product0 <= a0 * b0;
            product1 <= a1 * b1;
            product2 <= a2 * b2;
            product3 <= a3 * b3;

            valid_stage1 <= valid_in;

            // Stage 2: pairwise additions
            sum0 <= product0 + product1;
            sum1 <= product2 + product3;

            valid_stage2 <= valid_stage1;

            // Stage 3: final addition
            result <= sum0 + sum1;

            valid_out <= valid_stage2;

        end
    end

endmodule