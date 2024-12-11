`timescale 1ns / 1ps
module pipeline #(LENGTH=1, SIZE=1) (
    input wire clk_in,
    input wire [SIZE-1:0] val_in,
    output logic [SIZE-1:0] val_out
);
logic[SIZE-1:0] pipe[LENGTH-1:0];
always_ff @(posedge clk_in) begin
    for(int i = 1; i < LENGTH; ++i) begin
        pipe[i] <= pipe[i - 1];
    end
    pipe[0] <= val_in;
end
assign val_out = pipe[LENGTH-1];
endmodule
