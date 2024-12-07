`default_nettype none

module divider #(parameter WIDTH = 32) (input wire clk_in,
                input wire rst_in,
                input wire[WIDTH-1:0] dividend_in,
                input wire[WIDTH-1:0] divisor_in,
                input wire data_valid_in,
                output logic[WIDTH-1:0] quotient_out,
                output logic[WIDTH-1:0] remainder_out,
                output logic data_valid_out,
                output logic error_out,
                output logic busy_out);

  logic [31:0] p[31:0]; //32 stages
  logic [31:0] dividend [31:0]; //arrays of pipelined dividends and divisors
  logic [31:0] divisor [31:0];
  // logic data_valid [31:0]; //why did it start like this??
  logic [31:0] data_valid;

  //signed logic
  //signs of dividend and divisor, and sign_diff = 1 if they are different
  // dividend_sign=1 and divisor_sign=1 when negative
  logic dividend_sign, divisor_sign;
  logic sign_out;
  logic [31:0] sign;
  logic [31:0] dividend_in_unsigned;
  logic [31:0] divisor_in_unsigned;

  assign data_valid_out = data_valid[31];
  assign quotient_out = (sign_out) ? -dividend[31] : dividend[31]; // add a check for sign here
  assign remainder_out = p[31];


  always @(*) begin
    dividend_sign = dividend_in[31]; //(dividend_sign) ? -dividend_in : dividend_in;
    divisor_sign = divisor_in[31];
    sign[0] = (dividend_sign ^ divisor_sign); //XOR to find whether to negate the final answer
    sign_out = sign[31];
    dividend_in_unsigned = (dividend_sign) ? -dividend_in : dividend_in;
    divisor_in_unsigned = (divisor_sign) ? -divisor_in : divisor_in;

    data_valid[0] = data_valid_in;
    divisor[0] = divisor_in_unsigned; //correct it to make only positive
    if (data_valid_in)begin
      if ({31'b0,dividend_in_unsigned[31]}>=divisor_in_unsigned[31:0])begin
        p[0] = {31'b0,dividend_in_unsigned[31]} - divisor_in_unsigned[31:0];
        dividend[0] = {dividend_in_unsigned[30:0],1'b1};
      end else begin
        p[0] = {31'b0,dividend_in_unsigned[31]};
        dividend[0] = {dividend_in_unsigned[30:0],1'b0};
      end
    end
    for (int i=2; i<32; i=i+2)begin
      data_valid[i] = data_valid[i-1];
      sign[i] <= sign[i-1]; //pipeline the sign too
      if ({p[i-1][30:0],dividend[i-1][31]}>=divisor[i-1][31:0])begin
        p[i] = {p[i-1][30:0],dividend[i-1][31]} - divisor[i-1][31:0];
        dividend[i] = {dividend[i-1][30:0],1'b1};
      end else begin
        p[i] = {p[i-1][30:0],dividend[i-1][31]};
        dividend[i] = {dividend[i-1][30:0],1'b0};
      end
      divisor[i] = divisor[i-1];
    end
  end

  always_ff @(posedge clk_in)begin
    for (int i=1; i<32; i=i+2)begin
      data_valid[i] <= data_valid[i-1];
      sign[i] <= sign[i-1]; //pipeline the sign too
      if ({p[i-1][30:0],dividend[i-1][31]}>=divisor[i-1][31:0])begin
        p[i] <= {p[i-1][30:0],dividend[i-1][31]} - divisor[i-1][31:0];
        dividend[i] <= {dividend[i-1][30:0],1'b1};
      end else begin
        p[i] <= {p[i-1][30:0],dividend[i-1][31]};
        dividend[i] <= {dividend[i-1][30:0],1'b0};
      end
      divisor[i] <= divisor[i-1];
    end
  end
endmodule

`default_nettype wire
