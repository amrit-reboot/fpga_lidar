
`timescale 1ns/1ps

module tb;

    reg clk;
    reg reset;
    reg [7:0] data_reg;
    reg data_valid;

    wire packet_valid;
    wire [191:0] distances;

    reg [7:0] test_crc;
    reg [7:0] payload_byte;

    integer i;

    // Generate 100 MHz clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate LiDAR packet parser
    lsd02_parser uut (
        .clk(clk),
        .reset(reset),
        .data_reg(data_reg),
        .data_valid(data_valid),
        .packet_valid(packet_valid),
        .distances(distances)
    );

    // CRC-8 calculation for test packet
    function [7:0] crc8_next;
        input [7:0] crc_in;
        input [7:0] data_in;

        reg [7:0] crc;
        integer j;

        begin
            crc = crc_in ^ data_in;

            for (j = 0; j < 8; j = j + 1) begin
                if (crc[7] == 1'b1)
                    crc = (crc << 1) ^ 8'h4D;
                else
                    crc = crc << 1;
            end

            crc8_next = crc;
        end
    endfunction

    // Send one byte to the parser
    task send_byte;
        input [7:0] byte_value;

        begin
            @(negedge clk);
            data_reg = byte_value;
            data_valid = 1'b1;

            @(negedge clk);
            data_valid = 1'b0;
        end
    endtask

    initial begin

        // Initialize signals
        reset = 1'b1;
        data_reg = 8'h00;
        data_valid = 1'b0;
        test_crc = 8'h00;

        #20;
        reset = 1'b0;

        // Send packet header
        send_byte(8'h54);
        test_crc = crc8_next(test_crc, 8'h54);

        // Send length field
        send_byte(8'h2C);
        test_crc = crc8_next(test_crc, 8'h2C);

        // Send 44 payload bytes
        for (i = 0; i < 44; i = i + 1) begin

            payload_byte = 8'h00;

            // First distance = 500 mm = 0x01F4
            if (i == 4)
                payload_byte = 8'hF4;

            if (i == 5)
                payload_byte = 8'h01;

            send_byte(payload_byte);

            test_crc = crc8_next(test_crc, payload_byte);
        end

        // Send final CRC byte
        send_byte(test_crc);

        // Check parser outputs
        #1;

        if (distances[15:0] == 16'd500)
            $display("PASS: Distance = %d mm", distances[15:0]);
        else
            $display("FAIL: Distance = %d mm", distances[15:0]);

        $display("Calculated test CRC = %h", test_crc);

        #20;
        $finish;

    end

    // Observe valid packet pulse
    always @(posedge clk) begin
        if (packet_valid)
            $display("Packet valid at time %0t", $time);
    end

endmodule
