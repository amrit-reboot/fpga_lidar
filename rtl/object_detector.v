module object_detector(
    input reset,
    input wire clk ,
    input wire angles_valid, 
    input wire [191:0]distance,

    output reg detection_valid,
    output reg [11:0] detection_mask
);

    integer i ;
    reg [11:0] detected ;
    localparam [15:0] THRESHOLD = 16'd1000;

    always @(*) begin 
        for (i =0 ;i<=11;i=i+1)
            if((distance[i*16+:16]>0) && 
                (distance[i*16+:16]<THRESHOLD))
                detected[i] = 1'b1;
            else 
                detected[i] = 1'b0;
    end

    always @(posedge clk) begin
        if (reset) begin
            detection_mask  <= 12'd0;
            detection_valid <= 1'b0;
        end
        else if (angles_valid) begin
            detection_mask  <= detected;
            detection_valid <= 1'b1;
        end
        else begin
            detection_valid <= 1'b0;
        end
    end

endmodule 
