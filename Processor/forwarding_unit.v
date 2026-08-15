module forwarding_unit(
    input [1:0] id_ex_rs1,
    input [1:0] id_ex_rs2,
    input [1:0] ex_mem_rd,
    input ex_mem_regwrite,
    input [1:0] mem_wb_rd,
    input mem_wb_regwrite,
    output reg [1:0] fwd_A,
    output reg [1:0] fwd_B
);
always @(*) 
    begin
        fwd_A=2'b00;
        fwd_B=2'b00;

        if (ex_mem_regwrite && (ex_mem_rd == id_ex_rs1)) 
            fwd_A = 2'b10;
        else if (mem_wb_regwrite && (mem_wb_rd == id_ex_rs1)) 
            fwd_A = 2'b01;
        else 
         fwd_A = 2'b00;

        if (ex_mem_regwrite && (ex_mem_rd == id_ex_rs2)) 
            fwd_B = 2'b10;
        else if (mem_wb_regwrite && (mem_wb_rd == id_ex_rs2)) 
            fwd_B = 2'b01;
        else 
            fwd_B = 2'b00;
    end
endmodule