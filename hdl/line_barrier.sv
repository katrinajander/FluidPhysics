`default_nettype none

module line_barrier 
#(
    parameter HPIXELS, parameter VPIXELS,
    parameter VERT_START = 80, parameter VERT_END = 120,
    parameter HOR_START = 100, parameter HOR_END = 104
) (
    input wire [HOR_SIZE-1:0] hor_in,
    input wire [VERT_SIZE-1:0] vert_in,
    output wire in_barrier
);
localparam HOR_SIZE = $clog2(HPIXELS);
localparam VERT_SIZE = $clog2(VPIXELS);
assign in_barrier = (hor_in >= HOR_START) && (hor_in < HOR_END) && (vert_in >= VERT_START) && (vert_in < VERT_END);
endmodule

`default_nettype wire
