`default_nettype none

module principal_to_all #(parameter HPIXELS=205, parameter VPIXELS=154)
(
    input wire [HOR_SIZE-1:0] hor_in,
    input wire [VERT_SIZE-1:0] vert_in,
    output logic [8:0][HOR_SIZE-1:0] hor_out,
    output logic [8:0][VERT_SIZE-1:0] vert_out,
    output logic [8:0][BRAM_SIZE-1:0] addr_out
);
    localparam HOR_SIZE = $clog2(HPIXELS);
    localparam VERT_SIZE = $clog2(VPIXELS);
    localparam BRAM_DEPTH = HPIXELS * VPIXELS;
    localparam BRAM_SIZE = $clog2(BRAM_DEPTH);
    localparam RW_LATENCY = 3;

    generate
        genvar i;
        for(i=0;i<9;++i) begin
            addr_calc #(HPIXELS, VPIXELS) calc (
                .hor_in(hor_out[i]), 
                .vert_in(vert_out[i]),
                .addr_out(addr_out[i])
            );
        end
    endgenerate

    //              0        1      2         3       4         5       6        7       8
    // BRAM order: center, north, northeast, east, southeast, south, southwest, west, northwest
    //
    // principal order: L-R T-B
    // order works for 0 1 2 7 8
    //
    // reverse order works for rest
    always_comb begin
        hor_out = {
            hor_in,
            hor_in,
            hor_in,
            HPIXELS-hor_in,
            HPIXELS-hor_in,
            HPIXELS-hor_in,
            HPIXELS-hor_in,
            hor_in,
            hor_in
        };
        vert_out = {
            vert_in,
            vert_in,
            vert_in,
            VPIXELS-vert_in,
            VPIXELS-vert_in,
            VPIXELS-vert_in,
            VPIXELS-vert_in,
            vert_in,
            vert_in
        };
    end
endmodule

`default_nettype wire
