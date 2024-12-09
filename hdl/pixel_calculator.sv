`default_nettype none

module pixel_calculator #(parameter BRAM_DEPTH = 31570)(input wire pixel_clk_in,
                        input wire rst_in,
                        input wire [8:0][7:0] data_in,
                        input wire [10:0] hcount_in,
                        input wire [9:0] vcount_in,
                        output logic [BRAM_SIZE-1:0] addr_out,
                        output logic [7:0] red_out,
                        output logic [7:0] green_out,
                        output logic [7:0] blue_out);

localparam BRAM_SIZE = $clog2(BRAM_DEPTH);
logic [BRAM_SIZE-1:0] addr_out;

//get bram data in, set rgb stuff for that hcount and vcount
//somehow convert hcount, vcount to bram address but also 5x5 pixel squares
//but there is 2 cycle delay
//aaaah

logic [11:0] total_density;

always_comb begin
    total_density = data_in[0] + data_in[1] + data_in[2] + data_in[3] + data_in[4] + data_in[5] + data_in[6] +data_in[7] + data_in[8];
    //idk just set rgb to something for now based on total density
    //should do the math here
    // red_out = total_density[2:0];
    // green_out = total_density[5:3];
    // blue_out = total_density[11:6];
    //pink:
    red_out = 219;
    green_out = 48;
    blue_out = 130;
end

always_ff @(posedge pixel_clk_in)begin
    if (addr_out == BRAM_DEPTH) begin
        addr_out <= 0;
    end else begin
        addr_out <= addr_out + 1;
    end
end

endmodule

`default_nettype wire