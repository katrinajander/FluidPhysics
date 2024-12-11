`default_nettype none
module addr_calc #(parameter HPIXELS=205, parameter VPIXELS=154) (
    input wire [HOR_SIZE-1:0] hor_in,
    input wire [VERT_SIZE-1:0] vert_in,
    output logic [BRAM_SIZE-1:0] addr_out
);
    localparam HOR_SIZE = $clog2(HPIXELS);
    localparam VERT_SIZE = $clog2(VPIXELS);
    localparam BRAM_DEPTH = HPIXELS * VPIXELS;
    localparam BRAM_SIZE = $clog2(BRAM_DEPTH);

    assign addr_out = HOR_SIZE * vert_in + hor_in;
endmodule
`default_nettype wire
