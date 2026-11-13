
module lidar_top (
    input wire clk,
    input wire reset,
    input wire rx,

    output wire [191:0] angles,
    output wire angles_valid,

    output wire [11:0] detection_mask,
    output wire detection_valid
);

    wire [15:0] start_angle;
    wire [15:0] end_angle;
    wire packet_valid;

    wire [191:0] distances;
    wire [15:0] angle_span;

    reg [191:0] distances_aligned;
    wire [7:0] data_reg;
    wire data_valid;

    // LDS-02 UART receiver: 115200 baud, 8-N-1 at a 100 MHz clock.
    uart_rx uart_rx_inst (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .data_reg(data_reg),
        .data_valid(data_valid)
    );

    // Packet parser
    lsd02_parser parser_inst (
        .clk(clk),
        .reset(reset),
        .data_reg(data_reg),
        .data_valid(data_valid),
        .packet_valid(packet_valid),
        .distances(distances),
        .start_angle_out(start_angle),
        .end_angle_out(end_angle)
    );

    // Parallel angle calculator
    angle_calculator_parallel angle_cal (
        .clk(clk),
        .reset(reset),
        .start_angle(start_angle),
        .end_angle(end_angle),
        .packet_valid(packet_valid),
        .angle_span(angle_span),
        .angles(angles),
        .angles_valid(angles_valid)
    );

    // Align distances with calculated angles
    always @(posedge clk) begin
        if (reset)
            distances_aligned <= 192'd0;
        else if (packet_valid)
            distances_aligned <= distances;
    end

    // Object detector
    object_detector detector_inst (
        .clk(clk),
        .reset(reset),
        .angles_valid(angles_valid),
        .distance(distances_aligned),
        .detection_mask(detection_mask),
        .detection_valid(detection_valid)
    );

endmodule
