`default_nettype none

module principal_to_all #(parameter HPIXELS, parameter VPIXELS)
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
        hor_out[0] = hor_in;
        vert_out[0] = vert_in;

        hor_out[1] = hor_in;
        vert_out[1] = vert_in;

        hor_out[2] = hor_in;
        vert_out[2] = vert_in;

        hor_out[7] = hor_in;
        vert_out[7] = vert_in;

        hor_out[8] = hor_in;
        vert_out[8] = vert_in;

        hor_out[3] = HPIXELS-hor_in-1;
        vert_out[3] = VPIXELS-vert_in-1;

        hor_out[4] = HPIXELS-hor_in-1;
        vert_out[4] = VPIXELS-vert_in-1;

        hor_out[5] = HPIXELS-hor_in-1;
        vert_out[5] = VPIXELS-vert_in-1;

        hor_out[6] = HPIXELS-hor_in-1;
        vert_out[6] = VPIXELS-vert_in-1;
    end
endmodule

`default_nettype wire
