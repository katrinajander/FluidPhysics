`default_nettype none

module line_barrier #(parameter VERT_START = 80, parameter VERT_END = 120,
                    parameter HOR_START = 100, parameter HOR_END = 104)
                    (input wire clk_in,
                    input wire rst_in,
                    input wire [15:0] addr_in,
                    output logic bram_data_out);

//make a rectangle of barrier at the specific area
//and fill the rest with fluid moving right
//figure out what to do based on the input address

always_comb begin

end

endmodule

`default_nettype wire