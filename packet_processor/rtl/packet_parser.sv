//packet
// TYPE: 8bits
// Length: 8 bits
// ID: 16 bits
// Flag: 8 bits
// Payload: Variable length

//accpet a packet through ready/valid
//parse the header
//classify/filter
//attach a timestamp
//perform som processing
//buffer the result
//forward it

//I have three waves of input each 64(lets just say 64 for now) bits wide,
// the first wave is the header, the second wave is the payload A, 
//and the third wave is the payload B. The header will be parsed and classified, 
//


import packet_pkg::*;

typedef enum logic [1:0] {
    HEADER,
    PAYLOAD_A,
    PAYLOAD_B,
    OUTPUT
} parser_state_t;


module packet_parser #(
    parameter int WIDTH = 64,
    parameter int ID_WIDTH = 16,
    parameter int FLAG_WIDTH = 8,
    parameter int PAYLOAD_WIDTH = 256
)(
    input logic clk,
    input logic reset,

    // Input packet interface
    input logic valid_in,
    input logic downstream_ready,
    input logic [WIDTH-1:0] data_in,

    // Output packet interface
    output logic upstream_ready,
    output logic valid_out,
    output packet_t data_out
);


    parser_state_t state;

    always_comb begin
        upstream_ready = (state != OUTPUT);
    end

    always_ff @( posedge clk) begin
        if (reset) begin
            valid_out <= 1'b0;
            data_out <= '0;
            state <= HEADER;
        end else begin
            
            // Parse the incoming data into the packet structure
            case(state)
                HEADER: begin
                    if (valid_in && upstream_ready) begin
                        data_out.message_type <= data_in[63:56];
                        data_out.flags <= data_in[55:48];
                        data_out.id <= data_in[47:32];
                        data_out.length <= data_in[31:0];
                        state <= PAYLOAD_A; // Move to the next state to collect payload A
                    end
                end
                PAYLOAD_A: begin
                    if (valid_in && upstream_ready) begin
                        data_out.a0 <= data_in[63:48];
                        data_out.a1 <= data_in[47:32];
                        data_out.a2 <= data_in[31:16];
                        data_out.a3 <= data_in[15:0];
                        state <= PAYLOAD_B; // Move to the next state to collect payload B
                    end
                end
                PAYLOAD_B: begin
                    if (valid_in && upstream_ready) begin
                        data_out.b0 <= data_in[63:48];
                        data_out.b1 <= data_in[47:32];
                        data_out.b2 <= data_in[31:16];
                        data_out.b3 <= data_in[15:0];

                        valid_out <= 1'b1; // Indicate that the output is valid after collecting all parts of the packet
                        state <= OUTPUT; // Move to the next state to output the packet
                    end
                end
                OUTPUT: begin
                    
                    if(valid_out && downstream_ready ) begin
                        valid_out <= 1'b0; // Clear the valid signal after the packet has been accepted by the downstream module
                        state <= HEADER; // Reset to the initial state for the next packet
                    end
                end
            endcase
        end
    end




endmodule