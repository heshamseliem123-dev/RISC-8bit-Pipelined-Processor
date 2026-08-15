
module mem_addr_mux (
    input  wire [1:0]  ea_sel,
    input  wire [7:0]  alu_result, 
    input  wire [7:0]  rs1_data,
    input  wire [7:0]  next_byte,
    input  wire [7:0]  sp_addr,
    output reg  [7:0]  addr_out
);

    always @(*) begin
        case (ea_sel)
            2'b00: addr_out = {1'b1, next_byte[6:0]};   
            2'b01: addr_out = {1'b1, rs1_data[6:0]};    
            2'b10: addr_out = {1'b1, sp_addr[6:0]};     
            default: addr_out = {1'b1, alu_result[6:0]}; 
        endcase
    end

endmodule
