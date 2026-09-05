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

//when its valid but not ready, the buffer is full
//when its ready but not valid, it should wait for a valid packet
//when both are high, it should process the packet and forward it

//a fifo will have write enable withn input is valid and ready
//a fifo will have read enable when output is valid and ready

//input ready = not full
//output valid = not empty

// 64 bit input consisting of ID type flags and lenght
// 256 bit payload input of something i can dot product so a0 a1 a2 a3 b0 b1 b2 b3

//packets dont necessarily process all at once, they will come in multiple cycles ie.
// cylce 1: Header
// cycle 2: Payload
// cycle 3: Payload
// cycle 4: Payload

//just have a timestamp to check for latency

//how is it that the ready in signal will propagate correclty and not erase things
import packet_pkg::*;

module packet_processor #(
    parameter int WIDTH = 64,
    parameter int FIFO_DEPTH = 16
)(
    input logic clk,
    input logic reset,

    // Input packet interface
    input logic ready_out,
    input logic valid_in,
    input logic [WIDTH-1:0] data_in,

    // Output packet interface
    output logic ready_in,
    output logic valid_out,
    //output logic [WIDTH-1:0] data_out,
    output packet_t data_out
    //output logic [PAYLOAD_WIDTH-1:0] payload_out
);

//interface between modules

logic parser_valid_in;
logic parser_downstream_ready;
logic [WIDTH-1:0] parser_data_in;
logic parser_upstream_ready;
logic parser_valid_out;
packet_t parser_data_out;

logic filter_valid_in;
logic filter_downstream_ready;
packet_t filter_data_in;
logic filter_upstream_ready;
logic filter_valid_out;
packet_t filter_data_out;

logic timestamp_valid_in;
logic timestamp_downstream_ready;
packet_t timestamp_data_in;
logic timestamp_upstream_ready;
logic timestamp_valid_out;
packet_t timestamp_data_out;

logic dotp_valid_in;
packet_t dotp_data_in;
logic dotp_downstream_ready;
logic dotp_upstream_ready;
logic dotp_valid_out;
packet_t dotp_data_out;

logic fifo_valid_in;
logic fifo_downstream_ready;
logic fifo_upstream_ready;
logic fifo_valid_out;
packet_t fifo_data_in;
packet_t fifo_data_out;

assign ready_in = parser_upstream_ready;

assign parser_valid_in = valid_in;
assign parser_data_in = data_in;
assign parser_downstream_ready = filter_upstream_ready;

assign filter_valid_in = parser_valid_out;
assign filter_data_in = parser_data_out;
assign filter_downstream_ready = timestamp_upstream_ready;

assign timestamp_valid_in = filter_valid_out;
assign timestamp_data_in = filter_data_out;
assign timestamp_downstream_ready = dotp_upstream_ready;

assign dotp_valid_in = timestamp_valid_out;
assign dotp_data_in = timestamp_data_out;
assign dotp_downstream_ready = fifo_upstream_ready;

assign fifo_valid_in = dotp_valid_out;
assign fifo_data_in = dotp_data_out;
assign fifo_downstream_ready = ready_out;

assign valid_out = fifo_valid_out;
assign data_out = fifo_data_out;


packet_parser parser (
    .clk(clk),
    .reset(reset),
    .valid_in(parser_valid_in),
    .data_in(parser_data_in),
    .downstream_ready(parser_downstream_ready),
    .upstream_ready(parser_upstream_ready),
    .valid_out(parser_valid_out),
    .data_out(parser_data_out)
);

packet_filter filter (
    .clk(clk),
    .reset(reset),
    .valid_in(filter_valid_in),
    .data_in(filter_data_in),
    .downstream_ready(filter_downstream_ready),
    .upstream_ready(filter_upstream_ready),
    .valid_out(filter_valid_out),
    .data_out(filter_data_out)
);

packet_timestamp timestamp (
    .clk(clk),
    .reset(reset),
    .valid_in(timestamp_valid_in),
    .data_in(timestamp_data_in),
    .downstream_ready(timestamp_downstream_ready),
    .upstream_ready(timestamp_upstream_ready),
    .valid_out(timestamp_valid_out),
    .data_out(timestamp_data_out)
);

packet_dotp dopt(
    .clk(clk),
    .reset(reset),
    .valid_in(dotp_valid_in),
    .data_in(dotp_data_in),
    .downstream_ready(dotp_downstream_ready),
    .upstream_ready(dotp_upstream_ready),
    .valid_out(dotp_valid_out),
    .data_out(dotp_data_out)
);

fifo fifo(
    .clk(clk),
    .reset(reset),
    .valid_in(fifo_valid_in),
    .data_in(fifo_data_in),
    .ready_out(fifo_downstream_ready),
    .ready_in(fifo_upstream_ready),
    .valid_out(fifo_valid_out),
    .data_out(fifo_data_out)
);

endmodule