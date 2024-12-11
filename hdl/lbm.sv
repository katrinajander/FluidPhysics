`default_nettype none

module lbm #(parameter BRAM_DEPTH = 31570)(input wire clk_in,
                                            input wire rst_in,
                                            input wire [8:0][7:0] bram_data_in, //data read from bram
                                            input wire [15:0] sw_in,
                                            input wire btn_in,
                                            output logic [8:0][BRAM_SIZE-1:0] addr_out,
                                            output logic [8:0][7:0] bram_data_out,
                                            output logic valid_data_out); //data to write to bram

    // Major/minor FSM for Lattice Boltzmann Method
    localparam SETUP = 0;
    localparam COLLISION = 1;
    localparam STREAMING = 2;
    localparam WAITING = 3;
    logic [1:0] state;

    localparam BRAM_SIZE = $clog2(BRAM_DEPTH);
    logic [BRAM_SIZE-1:0] addr_counter; //counter from 0 to # lattice points (BRAM_DEPTH) (16 bits)

    logic [8:0][7:0] collision_in_data;
    logic [8:0][7:0] collision_out_data;
    logic start_collide;
    logic valid_collide;

    logic [8:0][7:0] streaming_in_data;
    logic [8:0][7:0] streaming_out_data;
    logic [8:0][BRAM_SIZE-1:0] streaming_addr_out;
    logic start_streaming;
    logic streaming_valid_out;
    logic done_streaming;

    //used to make collision step only once at a button press
    logic prev_btn;

    logic [2:0] start_collide_pipe;

    //              0        1      2         3       4         5       6        7       8
    // BRAM order: center, north, northeast, east, southeast, south, southwest, west, northwest

    always_ff @(posedge clk_in)begin
        if (rst_in)begin
            addr_counter <= 0;
            state <= SETUP;
            start_collide <= 0;
            start_collide_pipe <= 0;
            prev_btn <= 1;
            start_streaming <= 0;
            valid_data_out <= 0;
        end else begin
            prev_btn <= btn_in;
            start_collide_pipe[0] <= start_collide;
            for (int i=1; i<3; i = i+1)begin
                start_collide_pipe[i] <= start_collide_pipe[i-1];
            end
            case (state)
                SETUP: begin 
                    //done setting up:
                    if(addr_counter == BRAM_DEPTH) begin
                        state <= WAITING;
                        addr_counter <= 0;
                        valid_data_out <= 0;
                    end else begin
                        //set up fluid flow + barriers here. should put a different barrier based on switch combinations
                        //write to address at position # counter in the BRAM for East
                        //TODO 2 cycle delay here too ig but if theyre all the same it doesnt matter
                        for (int i=0; i<9; i=i+1)begin
                            case (sw_in[1:0])
                                2'b00: begin
                                    bram_data_out[i] <= 8'b00001010; //100 in each direction
                                    valid_data_out <= 1;
                                end
                                2'b01: begin
                                    bram_data_out[i] <= 8'b00000000; //minimum in each direction
                                    valid_data_out <= 1;
                                end
                                2'b10: begin
                                    bram_data_out[i] <= 8'b01111111; //maximum in each direction
                                    valid_data_out <= 1;
                                end
                                default: begin
                                    if (i == 3) begin
                                        bram_data_out[i] <= addr_counter & 8'b01111111; //east!
                                    end else begin
                                        bram_data_out[i] <= 8'b00001111; //every other direction!
                                    end
                                    valid_data_out <= 1;
                                end
                            endcase
                        end
                        addr_counter <= addr_counter + 1;
                    end
                    for(int i=0; i<9; ++i) begin
                        addr_out[i] <= addr_counter;
                    end
                end
                COLLISION: begin //do collision step
                    //done colliding
                    if (addr_counter == BRAM_DEPTH) begin
                        state <= STREAMING;
                        start_streaming <= 1;
                        addr_counter <= 0;
                        valid_data_out <= 0;
                    end else begin
                        //ok (temporary?) plan just feed it one value at a time and wait for valid_collide then move on to next value
                        if (valid_collide) begin
                            //save the results:
                            bram_data_out <= collision_out_data;
                            valid_data_out <= 1; //write enable to BRAM
                            //start new collision:
                            start_collide <= 1; //enable starting new collision
                            // read the next set of data (goes to addr_out next cycle,
                            // arrives 2 cycles after that)
                            // need to pipeline start_collide by 3 cycles
                            addr_counter <= addr_counter + 1;
                        end else begin
                            start_collide <= 0; //wait until the previous collision is done
                            valid_data_out <= 0; //don't write anything to BRAM
                        end
                        for(int i=0; i<9; ++i) begin
                            addr_out[i] <= addr_counter;
                        end
                    end
                end
                STREAMING: begin
                    start_streaming <= 0;
                    state <= done_streaming ? WAITING : STREAMING;
                    bram_data_out <= streaming_out_data;
                    //bram_data_out <= 72'h0A0A0A0A0A0A0A0A0A;
                    addr_out <= streaming_addr_out;
                    valid_data_out <= streaming_valid_out;
                    addr_counter <= 0;
                end
                WAITING: begin
                    valid_data_out <= 0;
                    if (btn_in && !prev_btn) begin //when btn is pressed and was previously unpressed
                        /*
                        start_collide <= 1;
                        addr_counter <= 0;
                        state <= COLLISION;
                        */
                        start_streaming <= 1;
                        state <= STREAMING;

                        addr_out <= 0;
                    end 
                end
            endcase
        end
    end

    //instatiate a collider
    collision collider (.clk_in(clk_in),
                        .rst_in(rst_in),
                        .data_in(bram_data_in), //9 8-bit numbers from BRAM
                        .data_valid_in(start_collide_pipe[2]), //high when there is real data to collide. probably once high, stays 1 for BRAM_DEPTH clock cycles
                        .data_out(collision_out_data), //9 8-bit numbers to write back to BRAM!
                        .done_colliding_out(valid_collide)); //signals that the colliding is done

    //instatiate a streamer here
    streaming streamer (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .start_in(start_streaming),
        .data_in(bram_data_in),
        .data_out(streaming_out_data),
        .addr_out(streaming_addr_out),
        .valid_data_out(streaming_valid_out),
        .done(done_streaming)
    );

endmodule

`default_nettype wire
