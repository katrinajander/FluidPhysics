`default_nettype none

module collision (input wire clk_in,
                input wire rst_in,
                input wire write_addr_in,
                input wire [8:0][7:0] data_in, //9 8-bit numbers from BRAM
                output logic [8:0][7:0] data_out, //results to write back to BRAM
                output logic done_colliding_out);

    // collide one set of values and write them back to the place in memory that you read from
    // set done_colliding to 1 when done
    logic [11:0] rho; //sized for adding 9 8-bit numbers
    logic signed [11:0] sum_x;
    logic signed [11:0] sum_y;
    logic signed [11:0] ux; //sum of x-directed densities / rho
    logic signed [11:0] uy; //sum of y-directed densities / rho
    logic [22:0] ux_squared;
    logic [22:0] uy_squared;

    divider divider_ux ( .clk_in(clk_in),
                .rst_in(rst_in),
                .dividend_in(sum_x),
                .divisor_in(rho),
                .data_valid_in(valid),
                .quotient_out(ux),
                .remainder_out(),
                .data_valid_out(valid_out),
                .error_out(),
                .busy_out());

     divider divider_uy ( .clk_in(clk_in),
                .rst_in(rst_in),
                .dividend_in(sum_y),
                .divisor_in(rho),
                .data_valid_in(valid),
                .quotient_out(uy),
                .remainder_out(),
                .data_valid_out(valid_out),
                .error_out(),
                .busy_out());

    always_ff @(posedge clk_in) begin
        // rho
        rho <= data_in[0] + data_in[1] + data_in[2] + data_in[3] + data_in[4] + data_in[5] + data_in[6] + data_in[7] + data_in[8];
        // velocity vectors
        sum_x <= data_in[2] + data_in[3] + data_in[4] - data_in[6] - data_in[7] - data_in[8];
        sum_y <= data_in[8] + data_in[1] + data_in[2] - data_out[4] - data_in[5] - data_in[6];

        // ux <= sum_x / rho after 32(?) cycles
        // uy <= sum_y / rho after 32(?) cycles

        // multiples of velocity vectors
        ux_times_3 <= 3 * ux;
        ux_squared <= ux * ux;
        uy_squared <= uy * uy;
        two_ux_uy <= 2 * ux * uy;

        // // fractions of rho
        // one_9th_rho <= rho / 9;
        // one_36th_rho <= rho / 36;

        // // updating data_out
        // data_out[0] <= (4 * one_9th_rho) * (1-); //center
        // data_out[1] <= ; //north
        // data_out[2] <= ; //northeast
        // data_out[3] <= ; //east
        // data_out[4] <= ; //southeast
        // data_out[5] <= ; //south
        // data_out[6] <= ; //southwest
        // data_out[7] <= ; //west
        // data_out[8] <= ; //northwest
    end

endmodule

`default_nettype wire