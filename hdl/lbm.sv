`default_nettype none

module lbm (input wire clk_in,
            input wire rst_in); // TODO add inputs and outputs
    parameter BRAM_DEPTH = 36864;

    // Major/minor FSM for Lattice Boltzmann Method
    localparam COLLISION = 0;
    localparam STREAMING = 1;
    logic state;

    logic [15:0] counter; //counter from 0 to # lattice points (BRAM_DEPTH) (16 bits)

    always_ff @(posedge clk_in)begin
        if (rst_in)begin
            counter <= 0;
            //probably more things too TODO
        end else begin
            case (state)
                COLLISION: begin //do collision step
                    if (counter == BRAM_DEPTH) begin
                        state <= STREAMING;
                        counter <= 0;
                    end else begin
                        counter <= counter + 1;
                        //update bram address + 1 but maybe thats the same as counter
                        //enable signal to collision module?
                        //also delay 2 cycles for bram reading
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

endmodule

`default_nettype wire