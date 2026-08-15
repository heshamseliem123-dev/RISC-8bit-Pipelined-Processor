module pc (
    input  wire        clk,
    input  wire        reset_in,   
    input  wire        pc_write,  
    input  wire [6:0]  pc_in,      
    output reg  [6:0]  pc_out      
);

always @(posedge clk or posedge reset_in) begin
    if (reset_in)
        pc_out <= 7'd0;        
    else if (pc_write)
        pc_out <= pc_in;       
    else
        pc_out <= pc_out;     
end

endmodule
