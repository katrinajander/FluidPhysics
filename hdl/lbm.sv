`default_nettype none

module lbm #(parameter BRAM_DEPTH = 31570)(input wire clk_in,
                                            input wire rst_in,
                                            input wire [8:0][7:0] bram_data_in, //data read from bram
                                            output [BRAM_SIZE-1:0] addr_out,
                                            output logic [8:0][7:0] bram_data_out); //data to write to bram

    // Major/minor FSM for Lattice Boltzmann Method
    localparam SETUP = 0;
    localparam COLLISION = 1;
    localparam STREAMING = 2;
    logic state;

    localparam BRAM_SIZE = $clog2(BRAM_DEPTH);
    logic [BRAM_SIZE-1:0] addr_counter; //counter from 0 to # lattice points (BRAM_DEPTH) (16 bits)

    logic [8:0][7:0] collision_in_data;
    logic [8:0][7:0] collision_out_data;
    logic start_collide;
    logic valid_collide;

    always_comb begin
        addr_out = addr_counter;
    end

    //              0        1      2         3       4         5       6        7       8
    // BRAM order: center, north, northeast, east, southeast, south, southwest, west, northwest

    always_ff @(posedge clk_in)begin
        if (rst_in)begin
            counter <= 0;
            //probably more things too TODO
        end else begin
            case (state)
                SETUP: begin 
                    //done setting up:
                    if(addr_counter == BRAM_DEPTH) begin
                        state <= COLLISION;
                        addr_counter <= 0;
                    end else begin
                        //set up fluid flow + barriers here (for now, just 50% flow East + 1 bit in each other direction)
                        //write to address at position # counter in the BRAM for East
                        for (int i=0; i<9; i=i+1)begin
                            if (i == 3) begin
                                bram_data_out[i] <= 8'b00001111; //east
                            end else begin
                                bram_data_out[i] <= 8'b00000001;
                            end
                        end
                        addr_counter <= addr_counter + 1;
                    end
                end
                COLLISION: begin //do collision step
                    //done colliding
                    if (addr_counter == BRAM_DEPTH) begin
                        state <= STREAMING;
                        addr_counter <= 0;
                    end else begin
                        //enable signal to collision module after 2 cycles for the delay?
                        collision_in_data <= bram_data_in;
                        bram_data_out <= collision_out_data;
                        if (valid_collide) begin
                            //waits NUM_STAGES cycles before first incrementing the counter
                            //after that it should increment every cycle
                            addr_counter <= addr_counter + 1;
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

    //instatiate a collider :)
    collision collider (.clk_in(clk_in),
                        .rst_in(rst_in),
                        .data_in(collision_in_data), //9 8-bit numbers from BRAM
                        .data_valid_in(), //high when there is real data to collide. probably once high, stays 1 for BRAM_DEPTH clock cycles
                        .data_out(collision_out_data), //results to write back to BRAM
                        .done_colliding_out(valid_collide)); //signals that the colliding is done

    //instatiate a streamer here

endmodule

`default_nettype wire