
module uart_rx (
    input wire clk,
    input wire reset,
    input wire rx,
    output reg [7:0] data_reg,
    output reg data_valid
);

    // FSM state definitions
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    // Current state register
    reg [1:0] state;
    reg [9:0] q;
    reg [2:0] bit_index;

    localparam HALF_BIT = 433;
    localparam FULL_BIT = 867;

    always @(posedge clk) begin
        if (reset == 1'b1) begin
            state <= IDLE;
            q <= 0;
            data_reg <= 0;
            bit_index <= 0;
            data_valid <= 0;
        end

        else begin
            data_valid <= 0;

            case (state)

                IDLE: begin
                    q <= 0;
                    bit_index <= 0;

                    if (rx == 0)
                        state <= START;
                    else
                        state <= IDLE;
                end

                START: begin
                    if (q == HALF_BIT) begin
                        q <= 0;

                        if (rx == 0)
                            state <= DATA;
                        else
                            state <= IDLE;
                    end
                    else begin
                        q <= q + 1;
                    end
                end

                DATA: begin
                    if (q == FULL_BIT) begin
                        q <= 0;
                        data_reg <= {rx, data_reg[7:1]};

                        if (bit_index == 3'd7) begin
                            bit_index <= 0;
                            state <= STOP;
                        end
                        else begin
                            bit_index <= bit_index + 1;
                        end
                    end
                    else begin
                        q <= q + 1;
                    end
                end

                STOP: begin
                    if (q == FULL_BIT) begin
                        q <= 0;

                        if (rx == 1)
                            data_valid <= 1;
                        else
                            data_valid <= 0;

                        state <= IDLE;
                    end
                    else begin
                        q <= q + 1;
                    end
                end

                default: begin
                    state <= IDLE;
                    q <= 0;
                end

            endcase
        end
    end

endmodule
