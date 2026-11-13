
module angle_calculator_parallel (
    input wire [15:0] start_angle,
    input wire [15:0] end_angle,
    output reg [15:0] angle_span,
    input wire clk,
    input wire reset,
    input wire packet_valid,
    output reg [191:0] angles,
    output reg angles_valid
);

    integer i;
    reg [31:0] angle_value;
    reg [191:0] calculated_angles;

    always @(*) begin
        if (end_angle >= start_angle)
            angle_span = end_angle - start_angle;
        else
            angle_span = 16'd36000 + end_angle - start_angle;

        for (i = 0; i < 12; i = i + 1) begin
            angle_value = start_angle + (i * angle_span) / 11;

            if (angle_value >= 36000)
                angle_value = angle_value - 36000;

            calculated_angles[i*16 +: 16] = angle_value[15:0];
        end
    end

    always @(posedge clk) begin 
        if(reset) begin 
            angles<=0;
            angles_valid<=0;
        end
        else if(packet_valid) begin
            angles<=calculated_angles;
            angles_valid<=1;
        end
        else 
            angles_valid<=0;
    end
endmodule
