`default_nettype none

module collision (input wire clk_in,
                input wire rst_in,
                input wire [8:0][7:0] data_in, //9 8-bit numbers from BRAM
                input wire data_valid_in, //real data valid to collide
                output logic [8:0][7:0] data_out, //results to write back to BRAM
                output logic done_colliding_out);

    divider #(.WIDTH(28)) divider_ux (.clk_in(clk_in),
                .rst_in(rst_in),
                .dividend_in(sum_x_extended),
                .divisor_in(rho_extended),
                .data_valid_in(valid_divide),
                .quotient_out(ux_extended),
                .remainder_out(),
                .data_valid_out(divide_x_valid_out),
                .error_out(),
                .busy_out());

    divider #(.WIDTH(28)) divider_uy ( .clk_in(clk_in),
                .rst_in(rst_in),
                .dividend_in(sum_y_extended),
                .divisor_in(rho_extended),
                .data_valid_in(valid_divide),
                .quotient_out(uy_extended),
                .remainder_out(),
                .data_valid_out(divide_y_valid_out),
                .error_out(),
                .busy_out());

    divider #(.WIDTH(28))divider_rho_36 (.clk_in(clk_in),
                .rst_in(rst_in),
                .dividend_in(rho_extended),
                .divisor_in(36),
                .data_valid_in(valid_divide),
                .quotient_out(one_36th_rho_extended),
                .remainder_out(),
                .data_valid_out(divide_rho_valid_out),
                .error_out(),
                .busy_out());
    
    divider #(.WIDTH(28)) divider_rho_9 (.clk_in(clk_in),
                .rst_in(rst_in),
                .dividend_in(rho_extended),
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
    logic [27:0] rho_extended;
    logic signed [27:0] sum_x_extended;
    logic signed [27:0] sum_y_extended;
    logic signed [27:0] ux_extended;
    logic signed [27:0] uy_extended;
    logic [27:0] one_36th_rho_extended;
    logic [27:0] one_9th_rho_extended;

    //other numbers for doing collision:
    logic signed [11:0] ux_times_3;
    logic signed [11:0] uy_times_3;
    logic [22:0] ux_squared;
    logic [22:0] uy_squared;
    logic [44:0] two_ux_uy;
    logic [44:0] u_squared;
    logic [44:0] u_squared_times_15;

    logic [7:0] data_out_zero;
    logic [11:0] data_out_rho;
    logic [11:0] data_out_from_in;

    // for testing
    logic valid_divide;
    logic divide_x_valid_out;
    logic divide_y_valid_out;
    logic divide_rho_valid_out;

    localparam NUM_STAGES = 18;
    localparam NUM_RHO_STAGES = 3;
    logic [NUM_STAGES:0][8:0][7:0] store_data_in;
    logic [NUM_STAGES:0] valid_out_pipeline;
    logic [NUM_RHO_STAGES:0][11:0] rho_9_pipeline;
    logic [NUM_RHO_STAGES:0][11:0] rho_36_pipeline;

    // delete these
    // logic [7:0] test_zero;
    // logic [7:0] test_one;
    // logic [7:0] test_two;
    // logic [7:0] test_three;
    // logic [7:0] test_four;
    // logic [7:0] test_five;
    // logic [7:0] test_six;
    // logic [7:0] test_seven;
    // logic [7:0] test_eight;

    // more registers for stages (third term taylor series)
    logic [22:0] ux_shifted;
    logic [22:0] uy_shifted;
    logic [22:0] u_2_shifted;

    always_comb begin
        rho_extended = {14'b0, rho};
        sum_x_extended = {6'b0, sum_x, 8'b0};
        sum_y_extended = {6'b0, sum_y, 8'b0};
        store_data_in[0] = data_in;
        valid_out_pipeline[0] = data_valid_in;
        if (divide_rho_valid_out) begin
            rho_9_pipeline[0] = one_9th_rho_extended[11:0];
            rho_36_pipeline[0] = one_36th_rho_extended[11:0];
        end
    end

    always_ff @(posedge clk_in) begin
        //pipeline the data_in stuff so that it can be used in the final calculation
        for (int i=1; i<NUM_STAGES+1; i=i+1)begin
            store_data_in[i] <= store_data_in[i-1];
            valid_out_pipeline[i] <= valid_out_pipeline[i-1];
        end
        
        for (int j=1; j<NUM_RHO_STAGES+1; j=j+1) begin
            rho_9_pipeline[j] <= rho_9_pipeline[j-1];
            rho_36_pipeline[j] <= rho_36_pipeline[j-1];
        end

        //Stage 1 (1 clock cycle)
        // rho
        if (data_in[5] == 255) begin //if barrier input is -1
            done_colliding_out <= 1;
            data_out[0] <= 255;
            data_out[1] <= 255;
            data_out[2] <= 255;
            data_out[3] <= 255;
            data_out[4] <= 255;
            data_out[5] <= 255;
            data_out[6] <= 255;
            data_out[7] <= 255;
            data_out[8] <= 255;
        end

        rho <= data_in[0] + data_in[1] + data_in[2] + data_in[3] + data_in[4] + data_in[5] + data_in[6] + data_in[7] + data_in[8];

        // delete these
        // test_zero <= data_in[0];
        // test_one <= data_in[1];
        // test_two <= data_in[2];
        // test_three <= data_in[3];
        // test_four <= data_in[4];
        // test_five <= data_in[5];
        // test_six <= data_in[6];
        // test_seven <= data_in[7];
        // test_eight <= data_in[8];

        // velocity vectors
        sum_x <= data_in[2] + data_in[3] + data_in[4] - data_in[6] - data_in[7] - data_in[8];
        sum_y <= data_in[8] + data_in[1] + data_in[2] - data_in[4] - data_in[5] - data_in[6];
        // valid signal for dividing to get ux, uy, rho/9, rho/36
        if (data_valid_in) begin
            valid_divide <= 1;
        end else begin
            valid_divide <= 0;
        end

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
        //fixed point 16
        u_squared <= ux * ux + uy * uy;
        u_squared_times_15 <= (3 * (ux * ux + uy * uy)) >> 1;

        //Stage 4: more intermediate results - taylor series!
        //aaaaaaah
        // these are all the third term of the taylor series for calculating data_out
        ux_shifted <= ((9*ux_squared) >> 2);
        uy_shifted <= ((9*uy_squared) >> 2);
        u_2_shifted <= ((9*(u_squared + two_ux_uy)) >> 2);

        //Stage 5 (1 clock cycle) updating data_out
        //lol hope this can be done in one clock cycle
        data_out[0] <= (4 * rho_9_pipeline[NUM_RHO_STAGES]) * (1 - u_squared_times_15); // - store_data_in[NUM_STAGES][0]; //center
        data_out[1] <= rho_9_pipeline[NUM_RHO_STAGES] * (1 + $signed(uy_times_3) + uy_shifted - u_squared_times_15); // - store_data_in[NUM_STAGES][1]; //north
        data_out[2] <= rho_36_pipeline[NUM_RHO_STAGES] * (1 + $signed(ux_times_3) + $signed(uy_times_3) + u_2_shifted - u_squared_times_15);// - store_data_in[NUM_STAGES][2]; //northeast
        data_out[3] <= rho_9_pipeline[NUM_RHO_STAGES] * (1 + $signed(uy_times_3) + ux_shifted - u_squared_times_15);// - store_data_in[NUM_STAGES][3]; //east
        data_out[4] <= rho_36_pipeline[NUM_RHO_STAGES] * (1 + $signed(ux_times_3) - $signed(uy_times_3) + u_2_shifted - u_squared_times_15);// - store_data_in[NUM_STAGES][4]; //southeast
        data_out[5] <= rho_9_pipeline[NUM_RHO_STAGES] * (1 - $signed(uy_times_3) + uy_shifted - u_squared_times_15);// - store_data_in[NUM_STAGES][5]; //south
        data_out[6] <= rho_36_pipeline[NUM_RHO_STAGES] * (1 - $signed(ux_times_3) - $signed(uy_times_3) + u_2_shifted - u_squared_times_15);// - store_data_in[NUM_STAGES][6]; //southwest
        data_out[7] <= rho_9_pipeline[NUM_RHO_STAGES] * (1 - $signed(ux_times_3) + ux_shifted - u_squared_times_15);// - store_data_in[NUM_STAGES][7]; //west
        data_out[8] <= rho_36_pipeline[NUM_RHO_STAGES] * (1 - $signed(ux_times_3) + $signed(uy_times_3) + u_2_shifted - u_squared_times_15);// - store_data_in[NUM_STAGES][8]; //northwest
        done_colliding_out <= valid_out_pipeline[NUM_STAGES];
    end

endmodule

`default_nettype wire