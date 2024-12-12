`default_nettype none

module circle_barrier 
#(
    parameter HPIXELS, parameter VPIXELS,
    parameter VERT_CENTRE = 80, parameter HOR_CENTRE = 120, parameter RADIUS=50
) (
    input wire [HOR_SIZE-1:0] hor_in,
    input wire [VERT_SIZE-1:0] vert_in,
    output logic in_barrier
);
localparam HOR_SIZE = $clog2(HPIXELS);
localparam VERT_SIZE = $clog2(VPIXELS);
logic [HOR_SIZE:0] hor_dist, vert_dist;
always_comb begin
    hor_dist = hor_in >= HOR_CENTRE ? hor_in - HOR_CENTRE : HOR_CENTRE - hor_in;
    vert_dist = vert_in >= VERT_CENTRE ? vert_in - VERT_CENTRE : VERT_CENTRE - vert_in;
    in_barrier = ((hor_dist * hor_dist) + (vert_dist * vert_dist)) < RADIUS;
end
endmodule

`default_nettype wire
