`default_nettype none

module pixel_calculator #(parameter BRAM_DEPTH = 31570)(input wire pixel_clk_in,
                        input wire test_button,
                        input wire rst_in,
                        input wire [8:0][7:0] data_in,
                        input wire [10:0] hcount_in,
                        input wire [9:0] vcount_in,
                        output logic [BRAM_SIZE-1:0] addr_out,
                        output logic [7:0] red_out,
                        output logic [7:0] green_out,
                        output logic [7:0] blue_out);

localparam BRAM_SIZE = $clog2(BRAM_DEPTH);

//get bram data in, set rgb stuff for that hcount and vcount
//but there is 2 cycle delay
//aaaah

logic [11:0] total_density;

always_comb begin
    //making a 4x4 pixel size grid because the division is easier
    //x = hcount >> 2, y = vcount >> 2
    //addr_out = x + 205*y
    //wait 2 cycles before setting red_out, etc?
    // addr_out = (hcount_in >> 2) + 205 * (vcount_in >> 2);
    //check for being in bounds, otherwise make the pixels black there to avoid artifacts

    total_density = data_in[0] + data_in[1] + data_in[2] + data_in[3] + data_in[4] + data_in[5] + data_in[6] +data_in[7] + data_in[8];
    addr_out = (hcount_in >> 2) + 205 * (vcount_in >> 2);

    if ((hcount_in >> 2) > 205 || (vcount_in >> 2) > 154 || (total_density == 2295)) begin // if it's out of the bram just make black
        //9 * 255 = 2295
        //everything is at max (8'b1) ie. -1 so there is a barrier to draw as black
        //or out of bounds of the display
        red_out = 0;
        green_out = 0;
        blue_out = 0;
    end else begin
        //just some function of the fluid density ig
        red_out = {total_density[11:8], 3'b0};
        green_out = {total_density[7:4], 3'b0};
        blue_out = {total_density[3:0], 3'b0};
        if (test_button) begin //make pink when button press :)
            red_out = 219;
            green_out = 48;
            blue_out = 130;
        end
    end
end

always_ff @(posedge pixel_clk_in)begin
    
end

endmodule

`default_nettype wire
