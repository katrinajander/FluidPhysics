`default_nettype none

module setup #(parameter HPIXELS, parameter VPIXELS)
(
    input wire clk_in,
    input wire rst_in,
    input wire start_in,
    input wire [1:0] setup_choice,
    output logic [8:0][7:0] data_out,
    output logic [8:0][BRAM_SIZE-1:0] addr_out,
    output logic done
);
localparam HOR_SIZE = $clog2(HPIXELS);
localparam VERT_SIZE = $clog2(VPIXELS);
localparam BRAM_DEPTH = HPIXELS * VPIXELS;
localparam BRAM_SIZE = $clog2(BRAM_DEPTH);
localparam RW_LATENCY = 3;

logic [HOR_SIZE-1:0] hor;
logic [VERT_SIZE-1:0] vert;
logic [BRAM_SIZE-1:0] addr;
logic in_setup;

logic in_barrier;

addr_calc #(HPIXELS, VPIXELS) calc (
    .hor_in(hor),
    .vert_in(vert),
    .addr_out(addr)
);

always_ff @(posedge clk_in) begin
    for(int i=0;i<9;++i) begin
        addr_out[i] <= addr;
    end
    if(rst_in) begin
        done <= 0;
        hor <= 0;
        in_setup <= 0;
        vert <= 0;
    end else begin
        if(!in_setup) begin
            in_setup <= start_in;
        end else begin
            if(vert == VPIXELS) begin
                done <= 1;
                hor <= 0;
                vert <= 0;
                in_setup <= 0;
            end else begin
                if(hor == HPIXELS - 1) begin
                    hor <= 0;
                    vert <= vert + 1;
                end else begin
                    hor <= hor + 1;
                end
                done <= 0;
                if(in_barrier) begin
                    data_out[0] <= -1;
                    for (int i=1; i<9; i=i+1) begin
                        data_out[i] <= 0;
                    end
                end else begin
                    for (int i=0; i<9; i=i+1) begin
                        if(i != 3) begin
                            data_out[i] <= 8'b00000011;
                        end else begin
                            data_out[i] <= 8'b00001111;
                        end
                    end
                end
            end
        end
    end
end
logic in_line_barrier, in_circle_barrier, in_lune_barrier;
line_barrier #(HPIXELS, VPIXELS) lb (
    .hor_in(hor),
    .vert_in(vert),
    .in_barrier(in_line_barrier)
);

circle_barrier #(HPIXELS, VPIXELS) cb (
    .hor_in(hor),
    .vert_in(vert),
    .in_barrier(in_circle_barrier)
);
always_comb begin
    case (setup_choice)
        2'b00: begin
            in_barrier = in_line_barrier;
        end
        2'b01: begin
            in_barrier = in_circle_barrier;
        end
        default: begin
            in_barrier = 0;
        end
    endcase
end
endmodule

`default_nettype wire
