

module sp_update (
    input  wire [1:0] sp_adj,        
    input  wire [7:0] sp_current,     
    output reg  [7:0] sp_next,        
    output reg  [7:0] sp_addr_used,   
    output reg        sp_write_enable
);

always @(*) begin
    sp_write_enable = 1'b0;
    sp_next         = sp_current;
    sp_addr_used    = sp_current;

    case (sp_adj)
        2'b01: begin
            
            sp_addr_used    = sp_current;
            sp_next         = sp_current - 8'd1;
            sp_write_enable = 1'b1;
        end

        2'b10: begin
           
            sp_next         = sp_current + 8'd1;
            sp_addr_used    = sp_current + 8'd1;
            sp_write_enable = 1'b1;
        end
    endcase
end

endmodule
