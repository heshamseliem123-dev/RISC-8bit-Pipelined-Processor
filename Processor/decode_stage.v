module decode_stage (
    input  wire        clk,
    input  wire        reset_in,

    input  wire [7:0]  instruction,
    input  wire [7:0]  next_byte,
    input  wire [6:0]  if_id_pc,

    input  wire [7:0]  rs1_data_in,
    input  wire [7:0]  rs2_data_in,

    input  wire [3:0]  ccr_in,

    input  wire        id_ex_clear,
    input  wire        stall,

    output wire [1:0]  if_id_rs1,
    output wire [1:0]  if_id_rs2,

    output reg  [7:0]  id_ex_rs1_data,
    output reg  [7:0]  id_ex_rs2_data,
    output reg  [7:0]  id_ex_imm_or_ea,
    output reg  [6:0]  id_ex_pc,
    output reg  [1:0]  id_ex_rs1,
    output reg  [1:0]  id_ex_rs2,
    output reg  [1:0]  id_ex_rd_index,
    output reg         id_ex_reg_write,
    output reg         id_ex_alu_src,
    output reg  [3:0]  id_ex_alu_op,
    output reg         id_ex_update_flags,
    output reg         id_ex_restore_flags,  // NEW: for RTI
    output reg         id_ex_mem_read,
    output reg         id_ex_mem_write,
    output reg         id_ex_mem_to_reg,
    output reg  [1:0]  id_ex_ea_sel,
    output reg  [1:0]  id_ex_sp_adj,
    output reg         id_ex_is_branch,
    output reg  [1:0]  id_ex_brx,
    output reg         id_ex_is_jump,
    output reg         id_ex_call,
    output reg         id_ex_ret,
    output reg         id_ex_rti,
    output reg         id_ex_is_L_format,    
    output reg         id_ex_control_valid,

    output reg         id_ex_io_read,
    output reg         id_ex_io_write,

    output wire [2:0]  cu_pc_sel,
    output wire        cu_is_L_format_out   
);

    wire [1:0] ra = instruction[3:2];
    wire [1:0] rb = instruction[1:0];
    assign if_id_rs1 = ra;
    assign if_id_rs2 = rb;

    // Control Unit wires
    wire        cu_reg_write;
    wire [1:0]  cu_rd_index;
    wire        cu_alu_src;
    wire        cu_update_flags;
    wire        cu_restore_flags;
    wire        cu_mem_read, cu_mem_write, cu_mem_to_reg;
    wire [1:0]  cu_ea_sel, cu_sp_adj;
    wire        cu_is_branch;
    wire [1:0]  cu_brx;
    wire        cu_is_jump, cu_call, cu_ret, cu_rti;
    wire        cu_is_L_format; 
    wire [3:0]  cu_alu_op;
    wire        cu_control_valid;
    wire        cu_io_read, cu_io_write;

    assign cu_is_L_format_out = cu_is_L_format;

    control_unit CU (
        .instruction   (instruction),
        .next_byte     (next_byte),
        .ccr_in        (ccr_in),
        .reset_in      (reset_in),

        .reg_write     (cu_reg_write),
        .rd_index      (cu_rd_index),
        .alu_src       (cu_alu_src),
        .update_flags  (cu_update_flags),
        .restore_flags (cu_restore_flags),

        .mem_read      (cu_mem_read),
        .mem_write     (cu_mem_write),
        .mem_to_reg    (cu_mem_to_reg),

        .ea_sel        (cu_ea_sel),
        .sp_adj        (cu_sp_adj),

        .is_branch     (cu_is_branch),
        .brx           (cu_brx),

        .is_jump       (cu_is_jump),
        .call          (cu_call),
        .ret           (cu_ret),
        .rti           (cu_rti),

        .pc_sel        (cu_pc_sel),

        .io_read       (cu_io_read),
        .io_write      (cu_io_write),

        .is_L_format   (cu_is_L_format),
        .alu_op        (cu_alu_op),
        .control_valid (cu_control_valid)
    );

    localparam [3:0] ALU_NOP = 4'd0;

    always @(posedge clk or posedge reset_in) begin
        if (reset_in) begin
            id_ex_rs1_data      <= 8'h00;
            id_ex_rs2_data      <= 8'h00;
            id_ex_imm_or_ea     <= 8'h00;
            id_ex_pc            <= 7'd0;
            id_ex_rs1           <= 2'b00;
            id_ex_rs2           <= 2'b00;
            id_ex_rd_index      <= 2'b00;
            id_ex_reg_write     <= 1'b0;
            id_ex_alu_src       <= 1'b0;
            id_ex_alu_op        <= ALU_NOP;
            id_ex_update_flags  <= 1'b0;
            id_ex_restore_flags <= 1'b0;
            id_ex_mem_read      <= 1'b0;
            id_ex_mem_write     <= 1'b0;
            id_ex_mem_to_reg    <= 1'b0;
            id_ex_ea_sel        <= 2'b00;
            id_ex_sp_adj        <= 2'b00;
            id_ex_is_branch     <= 1'b0;
            id_ex_brx           <= 2'b00;
            id_ex_is_jump       <= 1'b0;
            id_ex_call          <= 1'b0;
            id_ex_ret           <= 1'b0;
            id_ex_rti           <= 1'b0;
            id_ex_is_L_format   <= 1'b0;
            id_ex_control_valid <= 1'b0;
            id_ex_io_read       <= 1'b0;
            id_ex_io_write      <= 1'b0;
        end else if (id_ex_clear) begin

            id_ex_reg_write     <= 1'b0;
            id_ex_alu_src       <= 1'b0;
            id_ex_alu_op        <= ALU_NOP;
            id_ex_update_flags  <= 1'b0;
            id_ex_restore_flags <= 1'b0;
            id_ex_mem_read      <= 1'b0;
            id_ex_mem_write     <= 1'b0;
            id_ex_mem_to_reg    <= 1'b0;
            id_ex_ea_sel        <= 2'b00;
            id_ex_sp_adj        <= 2'b00;
            id_ex_is_branch     <= 1'b0;
            id_ex_brx           <= 2'b00;
            id_ex_is_jump       <= 1'b0;
            id_ex_call          <= 1'b0;
            id_ex_ret           <= 1'b0;
            id_ex_rti           <= 1'b0;
            id_ex_is_L_format   <= 1'b0;
            id_ex_control_valid <= 1'b0;
            id_ex_io_read       <= 1'b0;
            id_ex_io_write      <= 1'b0;
            id_ex_rs1_data      <= 8'h00;
            id_ex_rs2_data      <= 8'h00;
            id_ex_imm_or_ea     <= 8'h00;
            id_ex_pc            <= 7'd0;
            id_ex_rs1           <= 2'b00;
            id_ex_rs2           <= 2'b00;
            id_ex_rd_index      <= 2'b00;
        end else if (!stall) begin
      
            id_ex_rs1_data      <= rs1_data_in;
            id_ex_rs2_data      <= rs2_data_in;
            id_ex_imm_or_ea     <= next_byte;
            id_ex_pc            <= if_id_pc;
            id_ex_rs1           <= ra;
            id_ex_rs2           <= rb;
            id_ex_rd_index      <= cu_rd_index;
            id_ex_reg_write     <= cu_reg_write;
            id_ex_alu_src       <= cu_alu_src;
            id_ex_alu_op        <= cu_alu_op;
            id_ex_update_flags  <= cu_update_flags;
            id_ex_restore_flags <= cu_restore_flags;
            id_ex_mem_read      <= cu_mem_read;
            id_ex_mem_write     <= cu_mem_write;
            id_ex_mem_to_reg    <= cu_mem_to_reg;
            id_ex_ea_sel        <= cu_ea_sel;
            id_ex_sp_adj        <= cu_sp_adj;
            id_ex_is_branch     <= cu_is_branch;
            id_ex_brx           <= cu_brx;
            id_ex_is_jump       <= cu_is_jump;
            id_ex_call          <= cu_call;
            id_ex_ret           <= cu_ret;
            id_ex_rti           <= cu_rti;
            id_ex_is_L_format   <= cu_is_L_format;
            id_ex_control_valid <= cu_control_valid;
            id_ex_io_read       <= cu_io_read;
            id_ex_io_write      <= cu_io_write;
        end
    end

endmodule