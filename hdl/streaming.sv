`default_nettype none

module streaming #(parameter HPIXELS, parameter VPIXELS)
(
    input wire clk_in,
    input wire rst_in,
    input wire start_in,
    input wire [8:0][7:0] data_in,
    output logic [8:0][7:0] data_out,
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

    logic [8:0][HOR_SIZE-1:0] read_hor_0;
    logic [8:0][VERT_SIZE-1:0] read_vert_0;
    logic [8:0][BRAM_SIZE-1:0] read_addr_0, write_addr_0, read_addr_1, write_addr_1;

    logic [BRAM_SIZE-1:0] principal_addr, principal_addr_piped;
    logic [8:0][7:0] data_out_0, data_out_1;
    logic [8:0][7:0] data_in_flipped;

    logic valid_read, valid_write;

    principal_to_all #(HPIXELS, VPIXELS) explode(
        .hor_in(principal_hor),
        .vert_in(principal_vert),
        .hor_out(read_hor_0),
        .vert_out(read_vert_0),
        .addr_out(read_addr_0)
    );

    // + 1 since addr_out is registered
    addr_history #(HPIXELS, VPIXELS, RW_LATENCY + 1) hist(
        .clk_in(clk_in),
        .hor_in(read_hor_0),
        .vert_in(read_vert_0),
        .addr_out(write_addr_0)
    );

    addr_calc #(HPIXELS, VPIXELS) calc (
        .hor_in(principal_hor),
        .vert_in(principal_vert),
        .addr_out(principal_addr)
    );

    generate
        genvar i;
        for(i=0;i<9;++i) begin
            assign read_addr_1[i] = principal_addr;
            assign write_addr_1[i] = principal_addr_piped;
        end
    endgenerate

    always_comb begin
        data_in_flipped[0] = data_in[0];
        for(int i=1;i<9;++i) begin
            data_in_flipped[i] = (data_in[0] == 255) ? data_in[(i+3)%8+1] : data_in[i];
        end
    end

    pipeline #(RW_LATENCY + 1, BRAM_SIZE) write_addr_1_pipe(
        .clk_in(clk_in),
        .val_in(principal_addr),
        .val_out(principal_addr_piped)
    );


    // - 1 since reading from BRAM takes two cycles
    pipeline #(RW_LATENCY - 1, 72) data_pipe_0(
        .clk_in(clk_in),
        .val_in(data_in),
        .val_out(data_out_0)
    );

    pipeline #(RW_LATENCY - 1, 72) data_pipe_1(
        .clk_in(clk_in),
        .val_in(data_in_flipped),
        .val_out(data_out_1)
    );
    assign data_out = pass ? data_out_1 : data_out_0;

    // - 1 since valid_data_out is registered from valid_write
    pipeline #(RW_LATENCY - 1, 1) valid_pipe(
        .clk_in(clk_in),
        .val_in(valid_read),
        .val_out(valid_write)
    );

    localparam WAITING = 0;
    localparam READING = 1;
    localparam WRITING = 2;

    logic pass;

    always_ff @(posedge clk_in) begin
        if(pass == 0) begin
            addr_out <= valid_write ? write_addr_0 : read_addr_0;
        end else begin
            addr_out <= valid_write ? write_addr_1 : read_addr_1;
        end
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
                pass <= 0;
            end else begin
                if(principal_vert == VPIXELS) begin
                    valid_data_out <= 0;
                    principal_hor <= 0;
                    valid_read <= 0;
                    principal_vert <= 0;
                    if(pass == 0) begin
                        pass <= 1;
                        state <= READING;
                    end else begin
                        done <= 1;
                        pass <= 0;
                        state <= WAITING;
                    end
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
