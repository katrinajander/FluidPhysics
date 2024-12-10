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

  logic [WIDTH-1:0] p[WIDTH-1:0]; //WIDTH stages
  logic [WIDTH-1:0] dividend [WIDTH-1:0]; //arrays of pipelined dividends and divisors
  logic [WIDTH-1:0] divisor [WIDTH-1:0];
  // logic data_valid [WIDTH-1:0]; //why did it start like this??
  logic [WIDTH-1:0] data_valid;

  //signed logic
  //signs of dividend and divisor, and sign_diff = 1 if they are different
  // dividend_sign=1 and divisor_sign=1 when negative
  logic dividend_sign, divisor_sign;
  logic sign_out;
  logic [WIDTH-1:0] sign;
  logic [WIDTH-1:0] dividend_in_unsigned;
  logic [WIDTH-1:0] divisor_in_unsigned;

  assign data_valid_out = data_valid[WIDTH-1];
  assign quotient_out = (sign_out) ? -dividend[WIDTH-1] : dividend[WIDTH-1]; // add a check for sign here
  assign remainder_out = p[WIDTH-1];


  always @(*) begin
    dividend_sign = dividend_in[WIDTH-1]; //(dividend_sign) ? -dividend_in : dividend_in;
    divisor_sign = divisor_in[WIDTH-1];
    sign[0] = (dividend_sign ^ divisor_sign); //XOR to find whether to negate the final answer
    sign_out = sign[WIDTH-1];
    dividend_in_unsigned = (dividend_sign) ? -dividend_in : dividend_in;
    divisor_in_unsigned = (divisor_sign) ? -divisor_in : divisor_in;

    data_valid[0] = data_valid_in;
    divisor[0] = divisor_in_unsigned; //correct it to make only positive {(WIDTH-1){1'b0}}
    if (data_valid_in)begin
      if ({{(WIDTH-1){1'b0}},dividend_in_unsigned[WIDTH-1]}>=divisor_in_unsigned[WIDTH-1:0])begin
        p[0] = {{(WIDTH-1){1'b0}},dividend_in_unsigned[WIDTH-1]} - divisor_in_unsigned[WIDTH-1:0];
        dividend[0] = {dividend_in_unsigned[WIDTH-2:0],1'b1};
      end else begin
        p[0] = {{(WIDTH-1){1'b0}},dividend_in_unsigned[WIDTH-1]};
        dividend[0] = {dividend_in_unsigned[WIDTH-2:0],1'b0};
      end
    end
    for (int i=2; i<WIDTH; i=i+2)begin
      data_valid[i] = data_valid[i-1];
      sign[i] <= sign[i-1]; //pipeline the sign too
      if ({p[i-1][WIDTH-2:0],dividend[i-1][WIDTH-1]}>=divisor[i-1][WIDTH-1:0])begin
        p[i] = {p[i-1][WIDTH-2:0],dividend[i-1][WIDTH-1]} - divisor[i-1][WIDTH-1:0];
        dividend[i] = {dividend[i-1][WIDTH-2:0],1'b1};
      end else begin
        p[i] = {p[i-1][WIDTH-2:0],dividend[i-1][WIDTH-1]};
        dividend[i] = {dividend[i-1][WIDTH-2:0],1'b0};
      end
      divisor[i] = divisor[i-1];
    end
  end

  always_ff @(posedge clk_in)begin
    for (int i=1; i<WIDTH; i=i+2)begin
      data_valid[i] <= data_valid[i-1];
      sign[i] <= sign[i-1]; //pipeline the sign too
      if ({p[i-1][WIDTH-2:0],dividend[i-1][WIDTH-1]}>=divisor[i-1][WIDTH-1:0])begin
        p[i] <= {p[i-1][WIDTH-2:0],dividend[i-1][WIDTH-1]} - divisor[i-1][WIDTH-1:0];
        dividend[i] <= {dividend[i-1][WIDTH-2:0],1'b1};
      end else begin
        p[i] <= {p[i-1][WIDTH-2:0],dividend[i-1][WIDTH-1]};
        dividend[i] <= {dividend[i-1][WIDTH-2:0],1'b0};
      end
      divisor[i] <= divisor[i-1];
    end
  end
endmodule

`default_nettype wire
