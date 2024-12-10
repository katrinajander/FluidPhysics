`default_nettype none

module lbm #(parameter BRAM_DEPTH = 31570)(input wire clk_in,
                                            input wire rst_in,
                                            input wire [8:0][7:0] bram_data_in, //data read from bram
                                            input wire [15:0] sw_in,
                                            output logic [BRAM_SIZE-1:0] addr_out,
                                            output logic [8:0][7:0] bram_data_out,
                                            output logic valid_data_out); //data to write to bram

    // Major/minor FSM for Lattice Boltzmann Method
    localparam SETUP = 0;
    localparam COLLISION = 1;
    localparam STREAMING = 2;
    logic [1:0] state;

    localparam BRAM_SIZE = $clog2(BRAM_DEPTH);
    logic [BRAM_SIZE-1:0] addr_counter; //counter from 0 to # lattice points (BRAM_DEPTH) (16 bits)

    logic [8:0][7:0] collision_in_data;
    logic [8:0][7:0] collision_out_data;
    logic start_collide;
    logic valid_collide;

    always_comb begin
        addr_out = addr_counter - 1;
    end

    //              0        1      2         3       4         5       6        7       8
    // BRAM order: center, north, northeast, east, southeast, south, southwest, west, northwest

    always_ff @(posedge clk_in)begin
        if (rst_in)begin
            addr_counter <= 0;
            state <= SETUP;
            start_collide <= 0;
        end else begin
            case (state)
                SETUP: begin 
                    //done setting up:
                    if(addr_counter == BRAM_DEPTH) begin
                        state <= COLLISION;
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
                                    bram_data_out[i] <= 8'b11111111; //maximum in each direction
                                    valid_data_out <= 1;
                                end
                                default: begin
                                    if (i == 3) begin
                                        bram_data_out[i] <= 8'b11111111; //east! 00001010
                                    end else begin
                                        bram_data_out[i] <= 8'b00001111; //every other direction!
                                    end
                                    valid_data_out <= 1;
                                end
                            endcase
                        end
                        addr_counter <= addr_counter + 1;
                    end
                end
                COLLISION: begin //do collision step
                    //done colliding
                    if (addr_counter == BRAM_DEPTH) begin
                        state <= STREAMING;
                        addr_counter <= 0;
                    end else if (addr_counter == 0) begin
                        //start things
                        //TODO but also there is a 2 cycle delay
                        //pipeline it here
                        start_collide <= 1; //enable starting new collision
                        collision_in_data <= bram_data_in; //send this data to collide
                        addr_counter <= 1; //still want to write to 0, but also want to move on from here lol
                    end else begin
                        //ok (temporary?) plan just feed it one value at a time and wait for valid_collide then move on to next value
                        // if there is time, switch over to pipelining it again with read/write cycles alternating
                        start_collide <= 0;
                        if (valid_collide) begin
                            //save the results:
                            bram_data_out <= collision_out_data;
                            valid_data_out <= 1; //write enable to BRAM
                            //start new collision:
                            start_collide <= 1; //enable starting new collision
                            collision_in_data <= bram_data_in; //send this data to collide
                            addr_counter <= addr_counter + 1;
                        end else begin
                            start_collide <= 0; //wait until the previous collision is done
                            valid_data_out <= 0; //don't write anything to BRAM
                        end
                    end
                end
                STREAMING: begin
                    //do streaming module
                    //if done with STREAMING:
                    state <= COLLISION;
                end
            endcase
        end
    end

    //instatiate a collider
    collision collider (.clk_in(clk_in),
                        .rst_in(rst_in),
                        .data_in(collision_in_data), //9 8-bit numbers from BRAM
                        .data_valid_in(start_collide), //high when there is real data to collide. probably once high, stays 1 for BRAM_DEPTH clock cycles
                        .data_out(collision_out_data), //9 8-bit numbers to write back to BRAM!
                        .done_colliding_out(valid_collide)); //signals that the colliding is done

    //instatiate a streamer here

endmodule

`default_nettype wire