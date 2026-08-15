
module hazard_unit (
    input  wire [1:0] id_ex_rd,
    input  wire        id_ex_memread,
    input  wire [1:0] if_id_rs1,
    input  wire [1:0] if_id_rs2,
    input  wire        ex_branch_taken,
    input  wire        interrupt_flush,
    input  wire        mem_busy,       
    input  wire        is_L_format,    

    output reg         pc_write,
    output reg         if_id_write,
    output reg         if_id_clear,
    output reg         id_ex_clear,
    output reg         stall
);

always @(*) begin

    pc_write    = 1'b1;
    if_id_write = 1'b1;
    if_id_clear = 1'b0;
    id_ex_clear = 1'b0;
    stall       = 1'b0;

   
    if (id_ex_memread && ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2))) begin
        pc_write    = 1'b0;
        if_id_write = 1'b0;
        id_ex_clear = 1'b1; 
        stall       = 1'b1;
    end

 
    else if (mem_busy && is_L_format) begin
        pc_write    = 1'b0;
        if_id_write = 1'b0;
        id_ex_clear = 1'b1;
        stall       = 1'b1;
    end

    
    if (ex_branch_taken || interrupt_flush) begin
        if_id_clear = 1'b1;
       
        pc_write    = 1'b1; 
        if_id_write = 1'b1;
    end
end

endmodule