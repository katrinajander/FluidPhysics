`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
 
module tmds_encoder(
  input wire clk_in,
  input wire rst_in,
  input wire [7:0] data_in,  // video data (red, green or blue)
  input wire [1:0] control_in, //for blue set to {vs,hs}, else will be 0
  input wire ve_in,  // video data enable, to choose between control or video signal
  output logic [9:0] tmds_out
);
 
  logic [8:0] q_m; //already set to the output of tm_choice
  logic [4:0] tally; //5-bit 2s complement number
  logic [3:0] sum_1;
  logic [3:0] sum_0;
 
  tm_choice mtm(
    .data_in(data_in),
    .qm_out(q_m));
 
  //your code here.

  always_comb begin
    //combinational logic
    sum_1 = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7];
    sum_0 = (8 - sum_1);
  end

  always_ff @(posedge clk_in) begin
    if (rst_in == 1) begin
      //reset output to 0 and tally to 0
      tally <= 0;
      tmds_out <= 10'b0000000000;
    end else if (ve_in == 0) begin
      //video enable set to 0
      tally <= 0;
      if (control_in == 2'b00) begin 
        tmds_out <= 10'b1101010100;
      end else if (control_in == 2'b01) begin
        tmds_out <= 10'b0010101011;
      end else if (control_in == 2'b10) begin
        tmds_out <= 10'b0101010100;
      end else begin
        tmds_out <= 10'b1010101011;
      end
    end else begin
      if((tally == 0) || (sum_0 == sum_1)) begin
        //true path
        tmds_out[9] <= !q_m[8];
        tmds_out[8] <= q_m[8];
        tmds_out[7:0] <= (q_m[8]) ? q_m[7:0]: ~q_m[7:0];
        if (q_m[8] == 0) begin
          tally <= tally + (sum_0 - sum_1);
        end else begin
          tally <= tally + (sum_1 - sum_0);
        end
      end else begin
        //false path
        if (((tally[4] == 0) && (sum_1 > sum_0)) || ((tally[4] == 1) && (sum_0 > sum_1))) begin
          tmds_out[9] <= 1;
          tmds_out[8] <= q_m[8];
          tmds_out[7:0] <= ~q_m[7:0];
          tally <= tally + (2*q_m[8]) + (sum_0 - sum_1);
        end else begin
          tmds_out[9] <= 0;
          tmds_out[8] <= q_m[8];
          tmds_out[7:0] <= q_m[7:0];
          tally <= tally - (2*(!q_m[8])) + (sum_1 - sum_0);
        end
      end
    end
  end
 
endmodule
 
`default_nettype wire