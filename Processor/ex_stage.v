
module ex_stage (
    input  wire        clk,
    input  wire        reset_in,

    input  wire [7:0]  id_ex_rs1_data,
    input  wire [7:0]  id_ex_rs2_data,
    input  wire [7:0]  id_ex_imm_or_ea,
    input  wire [6:0]  id_ex_pc,

    input  wire [1:0]  id_ex_rs1,
    input  wire [1:0]  id_ex_rs2,
    input  wire [1:0]  id_ex_rd_index,

    input  wire        id_ex_reg_write,
    input  wire        id_ex_alu_src,
    input  wire [3:0]  id_ex_alu_op,
    input  wire        id_ex_update_flags,
    input  wire        id_ex_restore_flags,  
    input  wire        id_ex_mem_read,
    input  wire        id_ex_mem_write,
    input  wire        id_ex_mem_to_reg,
    input  wire [1:0]  id_ex_ea_sel,
    input  wire [1:0]  id_ex_sp_adj,
    input  wire        id_ex_is_branch,
    input  wire [1:0]  id_ex_brx,
    input  wire        id_ex_is_jump,
    input  wire        id_ex_call,
    input  wire        id_ex_ret,
    input  wire        id_ex_rti,
    input  wire        id_ex_control_valid,

  
    input  wire        id_ex_io_read,
    input  wire        id_ex_io_write,

 
    input  wire [1:0]  fwd_A,
    input  wire [1:0]  fwd_B,
    input  wire [7:0]  ex_mem_alu_result_fwd,
    input  wire [7:0]  mem_wb_writedata,

  
    input  wire        restore_ccr_in,      
    input  wire [3:0]  ccr_restore_data_in, 

    output wire [3:0]  ccr_out, // ccr_out[3:0] = {Z, N, C, V}
    output wire        ex_branch_taken,
    output wire [6:0]  ex_branch_target,


    output wire [7:0]  ex_mem_alu_result,
    output wire [7:0]  ex_mem_store_data,
    output wire [1:0]  ex_mem_rd_index,
    output wire        ex_mem_reg_write,
    output wire        ex_mem_mem_read,
    output wire        ex_mem_mem_write,
    output wire        ex_mem_mem_to_reg,
    output wire [1:0]  ex_mem_sp_adj,
    output wire [1:0]  ex_mem_ea_sel,
    output wire        ex_mem_call,
    output wire        ex_mem_ret,
    output wire        ex_mem_rti,
    output wire        ex_mem_is_jump,
    output wire        ex_mem_control_valid,
    output wire        ex_mem_restore_flags,  // NEW: for RTI
    
 
    output wire        ex_mem_io_read,
    output wire        ex_mem_io_write
);


    wire [7:0] opA_raw, opB_raw;

    mux4to1_8bit muxA (
        .sel(fwd_A),
        .d0(id_ex_rs1_data),
        .d1(mem_wb_writedata),
        .d2(ex_mem_alu_result_fwd),
        .d3(id_ex_rs1_data),
        .y (opA_raw)
    );

    mux4to1_8bit muxB (
        .sel(fwd_B),
        .d0(id_ex_rs2_data),
        .d1(mem_wb_writedata),
        .d2(ex_mem_alu_result_fwd),
        .d3(id_ex_rs2_data),
        .y (opB_raw)
    );


    wire [7:0] alu_in_a = opA_raw;
    wire [7:0] alu_in_b = id_ex_alu_src ? id_ex_imm_or_ea : opB_raw;

    wire [7:0] alu_result;
    wire alu_z, alu_n, alu_c, alu_v;

    ALU alu (
        .alu_op (id_ex_alu_op),
        .a      (alu_in_a),
        .b      (alu_in_b),
        .cin    (ccr_out[2]),  // C flag
        .result (alu_result),
        .z      (alu_z),
        .n      (alu_n),
        .c      (alu_c),
        .v      (alu_v)
    );

    ccr_reg CCR (
        .clk          (clk),
        .reset_in     (reset_in),
        .update_flags (id_ex_update_flags),
        .z_in         (alu_z),
        .n_in         (alu_n),
        .c_in         (alu_c),
        .v_in         (alu_v),
		.restore_flags (restore_ccr_in),     
    .ccr_restore   (ccr_restore_data_in), 
        .ccr_out      (ccr_out)
    );

    // Branch logic
    localparam ALU_DEC = 4'd9;
    wire is_loop = id_ex_is_branch && (id_ex_alu_op == ALU_DEC);

    branch_unit BRU (
        .is_branch    (id_ex_is_branch),
        .brx          (id_ex_brx),
        .is_loop      (is_loop),
        .ccr_in       (ccr_out),
        .alu_z        (alu_z),
        .branch_taken (ex_branch_taken)
    );

    assign ex_branch_target = opB_raw[6:0];

    ex_mem_reg EXMEM (
        .clk              (clk),
        .reset_in         (reset_in),

        .alu_result_in    (alu_result),
        .store_data_in    (opB_raw),
        .rd_index_in      (id_ex_rd_index),
        .reg_write_in     (id_ex_reg_write),
        .mem_read_in      (id_ex_mem_read),
        .mem_write_in     (id_ex_mem_write),
        .mem_to_reg_in    (id_ex_mem_to_reg),
        .sp_adj_in        (id_ex_sp_adj),

        .ea_sel_in        (id_ex_ea_sel),
        .call_in          (id_ex_call),
        .ret_in           (id_ex_ret),
        .rti_in           (id_ex_rti),
        .is_jump_in       (id_ex_is_jump),
        .control_valid_in (id_ex_control_valid),
        .restore_flags_in (id_ex_restore_flags),  // NEW

        .io_read_in       (id_ex_io_read),
        .io_write_in      (id_ex_io_write),

        .ex_mem_alu_result      (ex_mem_alu_result),
        .ex_mem_store_data      (ex_mem_store_data),
        .ex_mem_rd_index        (ex_mem_rd_index),
        .ex_mem_reg_write       (ex_mem_reg_write),
        .ex_mem_mem_read        (ex_mem_mem_read),
        .ex_mem_mem_write       (ex_mem_mem_write),
        .ex_mem_mem_to_reg      (ex_mem_mem_to_reg),
        .ex_mem_sp_adj          (ex_mem_sp_adj),

        .ex_mem_ea_sel          (ex_mem_ea_sel),
        .ex_mem_call            (ex_mem_call),
        .ex_mem_ret             (ex_mem_ret),
        .ex_mem_rti             (ex_mem_rti),
        .ex_mem_is_jump         (ex_mem_is_jump),
        .ex_mem_control_valid   (ex_mem_control_valid),
        .ex_mem_restore_flags   (ex_mem_restore_flags),  

        .ex_mem_io_read         (ex_mem_io_read),
        .ex_mem_io_write        (ex_mem_io_write)
    );

endmodule