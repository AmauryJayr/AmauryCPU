package packet_pkg;

typedef struct packed {
    logic [7:0] message_type;
    logic [7:0] flags;
    logic [15:0] id;
    logic [31:0] length;
    logic [63:0] timestamp;
    logic [15:0] a0, a1, a2, a3;
    logic [15:0] b0, b1, b2, b3;
    logic [33:0] result;
} packet_t;
endpackage