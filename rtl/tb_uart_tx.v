`timescale 1ns/1ps

module tb_uart_tx;
    localparam integer CLK_HZ = 100_000_000;
    localparam integer BAUD = 115_200;
    localparam integer CLKS_PER_BIT = CLK_HZ / BAUD;

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg tx_start = 1'b0;
    reg [7:0] data_in = 8'h00;
    wire tx;
    wire tx_busy;

    uart_tx #(
        .CLK_HZ(CLK_HZ),
        .BAUD(BAUD)
    ) dut (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .data_in(data_in),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    always #5 clk = ~clk;  // 10 ns period = 100 MHz

    task automatic check_frame(input [7:0] value);
        reg [9:0] expected_frame;
        integer bit_number;
        integer cycle;

        begin
            // Index 0 is the start bit. Indices 1 through 8
            // are the data bits, LSB first. Index 9 is the stop bit.
            expected_frame = {1'b1, value, 1'b0};

            @(negedge clk);
            if (tx !== 1'b1 || tx_busy !== 1'b0)
                $fatal(1, "UART was not idle before sending 0x%02h", value);

            data_in = value;
            tx_start = 1'b1;
            @(posedge clk);
            #1;
            tx_start = 1'b0;

            // Sample on falling edges, after the DUT updates on rising edges.
            for (bit_number = 0; bit_number < 10; bit_number = bit_number + 1) begin
                for (cycle = 0; cycle < CLKS_PER_BIT; cycle = cycle + 1) begin
                    @(negedge clk);

                    if (tx !== expected_frame[bit_number])
                        $fatal(1, "Byte 0x%02h, frame bit %0d, cycle %0d: expected tx=%b, got %b",
                               value, bit_number, cycle, expected_frame[bit_number], tx);

                    if (tx_busy !== 1'b1)
                        $fatal(1, "Byte 0x%02h: tx_busy cleared during frame bit %0d, cycle %0d",
                               value, bit_number, cycle);
                end
            end

            @(negedge clk);
            if (tx !== 1'b1 || tx_busy !== 1'b0)
                $fatal(1, "Byte 0x%02h: UART did not return to idle after the stop bit", value);

            $display("PASS: transmitted 0x%02h", value);
        end
    endtask

    initial begin
        repeat (3) @(negedge clk);
        if (tx !== 1'b1 || tx_busy !== 1'b0)
            $fatal(1, "Reset did not put the UART in idle");
        rst = 1'b0;

        check_frame(8'h53);
        check_frame(8'hA6);

        $display("PASS: all UART TX checks");
        $finish;
    end
endmodule