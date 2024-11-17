`default_nettype none

module lbm (input wire clk_in,
            input wire rst_in); // TODO fix inputs and outputs

    // Major/minor FSM for Lattice Boltzmann Method
    localparam COLLISION = 0;
    localparam STREAMING = 1;
    logic state;
    always_ff @(posedge clk_in)begin
        if (rst_in)begin
            //reset relevant things here
        end else begin
            case (state)
                COLLISION: begin
                    //do collision module
                    //if done with COLLISION:
                    state <= STREAMING;
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