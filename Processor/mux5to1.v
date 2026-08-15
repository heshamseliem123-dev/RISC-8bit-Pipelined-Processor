module mux5to1(
    input  [2:0] sel,       
    input  [6:0] d0, d1, d2, d3, d4, 
    output reg [6:0] y      
);

always @(*) begin
    case(sel)
        3'd0: y = d0;
        3'd1: y = d1;
        3'd2: y = d2;
        3'd3: y = d3;
        3'd4: y = d4;
        default: y = 7'b0;  
    endcase
end

endmodule