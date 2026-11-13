
module lsd02_parser (
    input wire clk,
    input wire reset,
    input wire [7:0] data_reg,
    input wire data_valid,

    output reg packet_valid,
    output reg [191:0] distances,
    output reg [15:0] start_angle_out,
    output reg [15:0] end_angle_out
);

    // Packet constants
    localparam [7:0] HEADER = 8'h54;
    localparam [7:0] LENGTH = 8'h2C;

    // FSM states
    localparam [1:0] WAIT_HEADER   = 2'b00;
    localparam [1:0] CHECK_LENGTH = 2'b01;
    localparam [1:0] READ_PAYLOAD = 2'b10;
    localparam [1:0] CHECK_CRC    = 2'b11;

    reg [1:0] state;
    reg [7:0] q;

    // Internal packet data
    reg [15:0] distance [0:11];
    reg [15:0] start_angle;
    reg [15:0] end_angle;

    reg [7:0] calculated_crc;

    integer i;

    // CRC-8 calculation
    function [7:0] crc8_next;
        input [7:0] crc_in;
        input [7:0] data_in;

        reg [7:0] crc;
        integer j;

        begin
            crc = crc_in ^ data_in;

            for (j = 0; j < 8; j = j + 1) begin
                if (crc[7])
                    crc = (crc << 1) ^ 8'h4D;
                else
                    crc = crc << 1;
            end

            crc8_next = crc;
        end
    endfunction

    // Main packet parser FSM
    always @(posedge clk) begin

        if (reset) begin
            state <= WAIT_HEADER;
            q <= 8'd0;

            calculated_crc <= 8'd0;
            packet_valid <= 1'b0;

            distances <= 192'd0;
            start_angle <= 16'd0;
            end_angle <= 16'd0;
            start_angle_out <= 16'd0;
            end_angle_out <= 16'd0;

            for (i = 0; i < 12; i = i + 1)
                distance[i] <= 16'd0;
        end

        else begin
            // Pulse high for one clock cycle
            packet_valid <= 1'b0;

            case (state)

                WAIT_HEADER: begin
                    if (data_valid) begin
                        if (data_reg == HEADER) begin
                            calculated_crc <=
                                crc8_next(8'h00, data_reg);

                            state <= CHECK_LENGTH;
                        end
                    end
                end

                CHECK_LENGTH: begin
                    if (data_valid) begin
                        if (data_reg == LENGTH) begin
                            q <= 8'd0;

                            calculated_crc <=
                                crc8_next(calculated_crc, data_reg);

                            state <= READ_PAYLOAD;
                        end
                        else if (data_reg == HEADER) begin
                            // Treat this byte as a new header
                            calculated_crc <=
                                crc8_next(8'h00, data_reg);

                            state <= CHECK_LENGTH;
                        end
                        else begin
                            state <= WAIT_HEADER;
                        end
                    end
                end

                READ_PAYLOAD: begin
                    if (data_valid) begin

                        case (q)

                            // Start angle
                            8'd2:  start_angle[7:0]   <= data_reg;
                            8'd3:  start_angle[15:8]  <= data_reg;

                            // Distance 0
                            8'd4:  distance[0][7:0]   <= data_reg;
                            8'd5:  distance[0][15:8]  <= data_reg;

                            // Distance 1
                            8'd7:  distance[1][7:0]   <= data_reg;
                            8'd8:  distance[1][15:8]  <= data_reg;

                            // Distance 2
                            8'd10: distance[2][7:0]   <= data_reg;
                            8'd11: distance[2][15:8]  <= data_reg;

                            // Distance 3
                            8'd13: distance[3][7:0]   <= data_reg;
                            8'd14: distance[3][15:8]  <= data_reg;

                            // Distance 4
                            8'd16: distance[4][7:0]   <= data_reg;
                            8'd17: distance[4][15:8]  <= data_reg;

                            // Distance 5
                            8'd19: distance[5][7:0]   <= data_reg;
                            8'd20: distance[5][15:8]  <= data_reg;

                            // Distance 6
                            8'd22: distance[6][7:0]   <= data_reg;
                            8'd23: distance[6][15:8]  <= data_reg;

                            // Distance 7
                            8'd25: distance[7][7:0]   <= data_reg;
                            8'd26: distance[7][15:8]  <= data_reg;

                            // Distance 8
                            8'd28: distance[8][7:0]   <= data_reg;
                            8'd29: distance[8][15:8]  <= data_reg;

                            // Distance 9
                            8'd31: distance[9][7:0]   <= data_reg;
                            8'd32: distance[9][15:8]  <= data_reg;

                            // Distance 10
                            8'd34: distance[10][7:0]  <= data_reg;
                            8'd35: distance[10][15:8] <= data_reg;

                            // Distance 11
                            8'd37: distance[11][7:0]  <= data_reg;
                            8'd38: distance[11][15:8] <= data_reg;

                            // End angle
                            8'd40: end_angle[7:0]     <= data_reg;
                            8'd41: end_angle[15:8]    <= data_reg;

                            default: begin
                                // Other payload bytes ignored
                            end

                        endcase

                        // Include every payload byte in CRC
                        calculated_crc <=
                            crc8_next(calculated_crc, data_reg);

                        if (q == 8'd43) begin
                            q <= 8'd0;
                            state <= CHECK_CRC;
                        end
                        else begin
                            q <= q + 1'b1;
                        end
                    end
                end

                CHECK_CRC: begin
                    if (data_valid) begin

                        if (data_reg == calculated_crc) begin

                            packet_valid <= 1'b1;

                            // Publish verified distances
                            for (i = 0; i < 12; i = i + 1) begin
                                distances[i*16 +: 16] <= distance[i];
                            end

                            // Publish verified angles
                            start_angle_out <= start_angle;
                            end_angle_out <= end_angle;

                        end

                        // Prepare for next packet
                        state <= WAIT_HEADER;
                    end
                end

                default: begin
                    state <= WAIT_HEADER;
                end

            endcase
        end
    end

endmodule
