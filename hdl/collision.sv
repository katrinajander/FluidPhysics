`default_nettype none

module collision (input wire clk_in,
                input wire rst_in,
                input wire write_addr_in,
                input wire [8:0][7:0] data_in, //9 8-bit numbers from BRAM
                output logic [8:0][7:0] data_out, //results to write back to BRAM
                output logic done_colliding_out);

    divider divider_ux (.clk_in(clk_in),
                .rst_in(rst_in),
                .dividend_in(sum_x_extended),
                .divisor_in(rho_extended),
                .data_valid_in(valid_divide),
                .quotient_out(ux_extended),
                .remainder_out(),
                .data_valid_out(),
                .error_out(),
                .busy_out());

    divider divider_uy ( .clk_in(clk_in),
                .rst_in(rst_in),
                .dividend_in(sum_y_extended),
                .divisor_in(rho_extended),
                .data_valid_in(valid_divide),
                .quotient_out(uy_extended),
                .remainder_out(),
                .data_valid_out(),
                .error_out(),
                .busy_out());

    divider divider_rho_36 (.clk_in(clk_in),
                .rst_in(rst_in),
                .dividend_in({18'b0, rho}),
                .divisor_in(36),
                .data_valid_in(valid_divide),
                .quotient_out(one_36th_rho_extended),
                .remainder_out(),
                .data_valid_out(),
                .error_out(),
                .busy_out());
    
    divider divider_rho_9 (.clk_in(clk_in),
                .rst_in(rst_in),
                .dividend_in({18'b0, rho}),
                .divisor_in(9),
                .data_valid_in(valid_divide),
                .quotient_out(one_9th_rho_extended),
                .remainder_out(),
                .data_valid_out(),
                .error_out(),
                .busy_out());

        // collide one set of values and write them back to the place in memory that you read from
    // set done_colliding to 1 when done
    logic [11:0] rho; //sized for adding 9 8-bit numbers
    logic signed [11:0] sum_x;
    logic signed [11:0] sum_y;
    logic signed [11:0] ux; //sum of x-directed densities / rho
    logic signed [11:0] uy; //sum of y-directed densities / rho
    logic [11:0] one_36th_rho;
    logic [11:0] one_9th_rho;

    // extended numbers to 32 bits to use during divisions
    logic [31:0] rho_extended;
    logic signed [31:0] sum_x_extended;
    logic signed [31:0] sum_y_extended;
    logic signed [31:0] ux_extended;
    logic signed [31:0] uy_extended;
    logic [31:0] one_36th_rho_extended;
    logic [31:0] one_9th_rho_extended;

    //other numbers for doing collision:
    logic signed [11:0] ux_times_3;
    logic signed [11:0] uy_times_3;
    logic [22:0] ux_squared;
    logic [22:0] uy_squared;
    logic [44:0] two_ux_uy;
    logic [44:0] u_squared;
    logic [44:0] u_squared_times_15;

    logic [7:0] data_out_zero;

    logic valid_divide;

    always_comb begin
        rho_extended = {18'b0, rho};
        sum_x_extended = { 10'b0, sum_x, 8'b0};
        sum_y_extended = {10'b0, sum_y, 8'b0};
    end

    always_ff @(posedge clk_in) begin
        //Stage 1 (1 clock cycle)
        // rho
        rho <= data_in[0] + data_in[1] + data_in[2] + data_in[3] + data_in[4] + data_in[5] + data_in[6] + data_in[7] + data_in[8];
        // velocity vectors
        sum_x <= data_in[2] + data_in[3] + data_in[4] - data_in[6] - data_in[7] - data_in[8];
        sum_y <= data_in[8] + data_in[1] + data_in[2] - data_in[4] - data_in[5] - data_in[6];
        // valid signal for dividing to get ux, uy, rho/9, rho/36
        valid_divide <= 1;

        //Stage 2 (16 clock cycles for the divider)
        // ux <= sum_x / rho
        // uy <= sum_y / rho
        //ux and uy are fixed point numbers with 8 bits after the fixed point
        ux <= ux_extended[11:0];
        uy <= uy_extended[11:0];
        // fractions of rho (these are just regular numbers)
        one_36th_rho <= one_36th_rho_extended[11:0];
        one_9th_rho <= one_9th_rho_extended[11:0];

        //Stage 3 (1 clock cycle)
        // multiples of velocity vectors
        //fixed point of 8 for these:
        ux_times_3 <= 3 * ux;
        uy_times_3 <= 3 * uy;
        //fixed point of 16 for these:
        ux_squared <= ux * ux;
        uy_squared <= uy * uy;
        two_ux_uy <= 2 * ux * uy;

        //Stage 4 (1 clock cycle)
        //fixed point 16
        u_squared <= ux_squared + uy_squared;

        //Stage 5 (1 clock cycle)
        u_squared_times_15 <= (3 * u_squared) >> 1; //maybe just put this below to save a clock cycle?

        // updating data_out
        //should clip negative numbers to 0?
        //rhos should be positive?
        data_out[0] <= (4 * one_9th_rho) * (1 - u_squared_times_15) - data_in[0]; //center
        // data_out_zero <= (4 * one_9th_rho) * (1 - u_squared_times_15) - data_in[0];
        data_out[1] <= one_9th_rho * (1 + uy_times_3 + ((9*uy_squared) >> 2) - u_squared_times_15) - data_in[1]; //north
        data_out[2] <= one_36th_rho * (1 + ux_times_3 + uy_times_3 + ((9*(ux_squared + two_ux_uy)) >> 2) - u_squared_times_15) - data_in[2]; //northeast
        data_out[3] <= one_9th_rho * (1 + uy_times_3 + ((9*ux_squared) >> 2) - u_squared_times_15) - data_in[3]; //east
        data_out[4] <= one_36th_rho * (1 + ux_times_3 - uy_times_3 + ((9*(ux_squared + two_ux_uy)) >> 2) - u_squared_times_15) - data_in[4]; //southeast
        data_out[5] <= one_9th_rho * (1 - uy_times_3 + ((9*uy_squared) >> 2) - u_squared_times_15) - data_in[5]; //south
        data_out[6] <= one_36th_rho * (1 - ux_times_3 - uy_times_3 + ((9*(ux_squared + two_ux_uy)) >> 2) - u_squared_times_15) - data_in[6]; //southwest
        data_out[7] <= one_9th_rho * (1 - ux_times_3 + ((9*ux_squared) >> 2) - u_squared_times_15) - data_in[7]; //west
        data_out[8] <= one_36th_rho * (1 - ux_times_3 + uy_times_3 + ((9*(ux_squared + two_ux_uy)) >> 2) - u_squared_times_15) - data_in[8]; //northwest
    end

endmodule

`default_nettype wire