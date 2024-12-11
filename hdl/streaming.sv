`default_nettype none

module streaming #(parameter HPIXELS=205, parameter VPIXELS=154)
(
    input wire clk_in,
    input wire rst_in,
    input wire start_in,
    input wire [7:0][8:0] data_in,
    output logic [7:0][8:0] data_out,
    output logic [8:0][BRAM_SIZE-1:0] addr_out,
    output logic valid_data_out,
    output logic done
);
    localparam HOR_SIZE = $clog2(HPIXELS);
    localparam VERT_SIZE = $clog2(VPIXELS);
    localparam BRAM_DEPTH = HPIXELS * VPIXELS;
    localparam BRAM_SIZE = $clog2(BRAM_DEPTH);
    localparam RW_LATENCY = 3;

    logic [1:0] state;
    logic [HOR_SIZE-1:0] principal_hor;
    logic [VERT_SIZE-1:0] principal_vert;

    logic [8:0][HOR_SIZE-1:0] read_hor;
    logic [8:0][VERT_SIZE-1:0] read_vert;
    logic [8:0][BRAM_SIZE-1:0] read_addr, write_addr;

    logic valid_read, valid_write;

    principal_to_all #(HPIXELS, VPIXELS) explode(
        .hor_in(principal_hor),
        .vert_in(principal_vert),
        .hor_out(read_hor),
        .vert_out(read_vert),
        .addr_out(read_addr)
    );

    addr_history #(HPIXELS, VPIXELS, RW_LATENCY) hist(
        .clk_in(clk_in),
        .hor_in(read_hor),
        .vert_in(read_vert),
        .addr_out(write_addr)
    );

    pipeline #(RW_LATENCY-2, 72) data_pipe(
        .clk_in(clk_in),
        .val_in(data_in),
        .val_out(data_out)
    );

    pipeline #(RW_LATENCY-1, 1) valid_pipe(
        .clk_in(clk_in),
        .val_in(valid_read),
        .val_out(valid_write)
    );

    localparam WAITING = 0;
    localparam READING = 1;
    localparam WRITING = 2;

    always_ff @(posedge clk_in) begin
        addr_out <= valid_write ? write_addr : read_addr;
        if(rst_in) begin
            valid_data_out <= 0;
            done <= 0;
            principal_hor <= 0;
            principal_vert <= 0;
            valid_read <= 0;
            state <= WAITING;
        end else begin
            if(state == WAITING) begin
                valid_data_out <= 0;
                done <= 0;
                principal_hor <= 0;
                principal_vert <= 0;
                valid_read <= 0;
                state <= start_in ? READING : WAITING;
            end else begin
                if(principal_vert == VPIXELS && principal_hor == 1) begin
                    valid_data_out <= 0;
                    done <= 1;
                    principal_hor <= 0;
                    valid_read <= 0;
                    principal_vert <= 0;
                    state <= WAITING;
                end else begin
                    done <= 0;
                    if(state == READING) begin
                        valid_data_out <= 0;
                        valid_read <= 1;
                        state <= WRITING;
                    end else if(state == WRITING) begin
                        valid_read <= 0;
                        valid_data_out <= valid_write;
                        if(principal_hor == HPIXELS - 1) begin
                            principal_hor <= 0;
                            principal_vert <= principal_vert + 1;
                        end else begin
                            principal_hor <= principal_hor + 1;
                        end
                        state <= READING;
                    end
                end
            end
        end
    end
endmodule

`default_nettype wire
