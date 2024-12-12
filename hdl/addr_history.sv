`default_nettype none
module addr_history #(parameter HPIXELS, parameter VPIXELS, parameter LATENCY=3) (
    input wire clk_in,
    input wire [8:0][HOR_SIZE-1:0] hor_in,
    input wire [8:0][VERT_SIZE-1:0] vert_in,
    output logic [8:0][BRAM_SIZE-1:0] addr_out
);
    localparam HOR_SIZE = $clog2(HPIXELS);
    localparam VERT_SIZE = $clog2(VPIXELS);
    localparam BRAM_DEPTH = HPIXELS * VPIXELS;
    localparam BRAM_SIZE = $clog2(BRAM_DEPTH);
    
    logic [8:0][BRAM_SIZE-1:0] addr_intermediate;
    logic [8:0][HOR_SIZE-1:0] hor_intermediate;
    logic [8:0][VERT_SIZE-1:0] vert_intermediate;

    generate
        genvar i;
        for(i=0;i<9;++i) begin
            addr_calc #(HPIXELS, VPIXELS) calc (
                .hor_in(hor_intermediate[i]), 
                .vert_in(vert_intermediate[i]),
                .addr_out(addr_intermediate[i])
            );
        end
    endgenerate

    pipeline #(LATENCY, BRAM_SIZE*9) addr_pipe(
        .clk_in(clk_in),
        .val_in(addr_intermediate),
        .val_out(addr_out)
    );

    //              0        1      2         3       4         5       6        7       8
    // BRAM order: center, north, northeast, east, southeast, south, southwest, west, northwest
    //
    // periodic boundary conditions
    always_comb begin
        hor_intermediate[0] = hor_in[0];
        vert_intermediate[0] = vert_in[0];

        hor_intermediate[1] = hor_in[1];
        vert_intermediate[1] = vert_in[1] == 0 ? VPIXELS-1 : vert_in[1] - 1;

        hor_intermediate[2] = hor_in[2] == HPIXELS - 1 ? 0 : hor_in[2] + 1;
        vert_intermediate[2] = vert_in[2] == 0 ? VPIXELS-1 : vert_in[2] - 1;

        hor_intermediate[3] = hor_in[3] == HPIXELS - 1 ? 0 : hor_in[3] + 1;
        vert_intermediate[3] = vert_in[3];

        hor_intermediate[4] = hor_in[4] == HPIXELS - 1 ? 0 : hor_in[4] + 1;
        vert_intermediate[4] = vert_in[4] == VPIXELS - 1 ? 0 : vert_in[4] + 1;

        hor_intermediate[5] = hor_in[5];
        vert_intermediate[5] = vert_in[5] == VPIXELS - 1 ? 0 : vert_in[5] + 1;

        hor_intermediate[6] = hor_in[6] == 0 ? HPIXELS - 1 : hor_in[6] - 1;
        vert_intermediate[6] = vert_in[6] == VPIXELS - 1 ? 0 : vert_in[6] + 1;

        hor_intermediate[7] = hor_in[7] == 0 ? HPIXELS - 1 : hor_in[7] - 1;
        vert_intermediate[7] = vert_in[7];

        hor_intermediate[8] = hor_in[8] == 0 ? HPIXELS - 1 : hor_in[8] - 1;
        vert_intermediate[8] = vert_in[8] == 0 ? VPIXELS - 1 : vert_in[8] - 1;
    end
endmodule
`default_nettype wire
