module uart_tx #(
    parameter integer CLK_HZ= 100_000_000,
    parameter integer BAUD= 115_200
)(
    input wire clk,
    input wire rst,
    input wire tx_start,
    input wire [7:0] data_in,
    output reg tx,
    output reg tx_busy
);
    localparam integer CLKS_PER_BIT = CLK_HZ / BAUD;
    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] START= 2'b01;
    localparam [1:0] DATA = 2'b10;
    localparam [1:0] STOP = 2'b11;
    localparam integer COUNT_WIDTH = (CLKS_PER_BIT > 1) ? $clog2(CLKS_PER_BIT) : 1;
    reg [1:0] state;
    reg [7:0] tx_byte;
    reg [COUNT_WIDTH-1:0] baud_count;
    reg [2:0] bit_index;
    
    always @(posedge clk) begin
        if (rst) begin
            state<= IDLE;
            tx <= 1'b1;
            tx_busy <= 1'b0;
            tx_byte<= 8'd0;
            baud_count<= 0;
            bit_index<= 3'd0;

        end
        else begin
            case(state)
                IDLE : begin
                    
                    if (tx_start) begin 
                        tx_byte <= data_in ;
                        tx_busy<= 1'b1;
                        tx<= 1'b0;
                        state<= START;
                        baud_count <= 0;
                        bit_index<= 3'd0;
                    end
                    else begin
                        tx_busy<= 1'b0 ;
                        tx<= 1'b1;
                    end


                end
                START: begin
                    if (baud_count== CLKS_PER_BIT-1) begin 
                        baud_count<= 0;
                        tx <= tx_byte[0];
                        state <= DATA;
                    end
                    else begin
                        baud_count<= baud_count + 1'b1;
                    end
                end
                DATA: begin
                    
                    if(baud_count== CLKS_PER_BIT-1) begin
                        baud_count <= 0;
                        if(bit_index==3'd7) begin
                            tx<= 1'b1;
                            state<= STOP;
                        end
                        else begin
                            tx<= tx_byte[bit_index+3'd1];
                            bit_index<=bit_index+3'd1;
                        end
                    end else begin
                            baud_count<= baud_count+1'b1;
                        end
                
                end

                STOP: begin
                    if (baud_count == CLKS_PER_BIT - 1) begin
                        baud_count <= 0;
                        tx_busy<= 1'b0;
                        state<= IDLE;
                    end 
                    else begin
                        baud_count <= baud_count +1'b1;
                    end
                end
            endcase
        end
    end
    endmodule




