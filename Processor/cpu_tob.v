
module cpu_tob (
    input  wire        clk,
    input  wire        reset_in,
    input  wire        intr_in,
    input  wire [7:0]  IN_PORT,
    output wire [7:0]  OUT_PORT
);

    wire [7:0] mem_addr_a, mem_rd_a, mem_addr_b_fetch, mem_addr_b_mem, mem_addr_b, mem_rd_b, mem_wd_b_mem, mem_wd_b;
    wire       mem_re_a, mem_re_b_fetch, mem_re_b_mem, mem_we_b_mem, mem_re_b, mem_we_b;
    wire       pc_write, if_id_write, if_id_clear, id_ex_clear, hazard_stall, rti_busy, is_L_format;
    wire [7:0] if_id_instruction, if_id_next_byte;
    wire [6:0] if_id_pc;
    wire [1:0] if_id_rs1, if_id_rs2;
    wire [7:0] rs1_data, rs2_data, sp_next, sp_value, wb_rd_data;
    wire [1:0] wb_rd_index;
    wire       wb_reg_write, sp_we, restore_ccr;
    wire [3:0] ccr_out, ccr_restore_data;

    // ID/EX Pipeline Wires
    wire [7:0] id_ex_rs1_data, id_ex_rs2_data, id_ex_imm_or_ea;
    wire [6:0] id_ex_pc;
    wire [1:0] id_ex_rs1, id_ex_rs2, id_ex_rd_index;
    wire [3:0] id_ex_alu_op;
    wire [1:0] id_ex_ea_sel, id_ex_sp_adj;
    wire [1:0] id_ex_brx; 
    wire       id_ex_reg_write, id_ex_alu_src, id_ex_update_flags, id_ex_restore_flags;
    wire       id_ex_mem_read, id_ex_mem_write, id_ex_mem_to_reg, id_ex_io_read, id_ex_io_write;
    wire       id_ex_is_branch, id_ex_is_jump, id_ex_call, id_ex_ret, id_ex_rti, id_ex_is_L_format, id_ex_control_valid;

    // EX/MEM Pipeline Wires
    wire [7:0] ex_mem_alu_result, ex_mem_store_data;
    wire [1:0] ex_mem_rd_index, ex_mem_sp_adj, ex_mem_ea_sel;
    wire       ex_mem_reg_write, ex_mem_mem_read, ex_mem_mem_write, ex_mem_mem_to_reg;
    wire       ex_mem_ret, ex_mem_rti, ex_mem_is_jump, ex_mem_restore_flags, ex_mem_io_read, ex_mem_io_write;
    wire       ex_mem_control_valid, ex_mem_call, ex_branch_taken;
    wire [6:0] branch_target;

    // Interrupt & Forwarding
    wire       intr_done, intr_interrupt_flush;
    wire       intr_busy, intr_push_pc, intr_push_ccr, intr_rd_isr;
    wire [7:0] intr_isr_value;
    wire [1:0] fwd_A, fwd_B;
    wire       mem_portb_busy, combined_mem_busy;

    // ------------------------------------------------------
    // 2. Memory & Control Logic
    // ------------------------------------------------------
    assign mem_portb_busy    = mem_re_b_mem | mem_we_b_mem;
    assign combined_mem_busy = mem_portb_busy | rti_busy;
    assign mem_addr_b = mem_portb_busy ? mem_addr_b_mem : mem_addr_b_fetch;
    assign mem_re_b   = mem_portb_busy ? mem_re_b_mem   : mem_re_b_fetch;
    assign mem_we_b   = mem_portb_busy ? mem_we_b_mem   : 1'b0;
    assign mem_wd_b   = mem_portb_busy ? mem_wd_b_mem   : 8'h00;

    wire [2:0] pc_sel = (intr_done)               ? 3'b100 : 
                        (ex_mem_ret | ex_mem_rti) ? 3'b011 : 
                        (ex_mem_is_jump)          ? 3'b010 : 
                        (ex_branch_taken)         ? 3'b001 : 
                                                    3'b000;  // Sequential PC

    // ------------------------------------------------------
    // 3. Modules Instantiation
    // ------------------------------------------------------

    memory_dualport UNIFIED_MEM (
        .clk(clk), .addr_a(mem_addr_a), .re_a(mem_re_a), .rd_a(mem_rd_a),
        .addr_b(mem_addr_b), .re_b(mem_re_b), .we_b(mem_we_b), .wd_b(mem_wd_b), .rd_b(mem_rd_b)
    );

    hazard_unit HU (
        .id_ex_rd(id_ex_rd_index), .id_ex_memread(id_ex_mem_read),
        .if_id_rs1(if_id_rs1), .if_id_rs2(if_id_rs2),
        .ex_branch_taken(ex_branch_taken), .interrupt_flush(intr_interrupt_flush),
        .mem_busy(combined_mem_busy), .is_L_format(is_L_format),
        .pc_write(pc_write), .if_id_write(if_id_write), .if_id_clear(if_id_clear),
        .id_ex_clear(id_ex_clear), .stall(hazard_stall)
    );

    fetch_stage FETCH (
        .clk(clk), .reset_in(reset_in), .pc_write(pc_write), .if_id_write(if_id_write), .if_id_clear(if_id_clear),
        .pc_sel(pc_sel), .branch_target(branch_target), .jump_target(id_ex_rs2_data[6:0]),
        .ret_addr(mem_rd_b[6:0]), .isr_value(intr_isr_value[6:0]), .ex_branch_taken(ex_branch_taken),
        .addr_a(mem_addr_a), .re_a(mem_re_a), .rd_a(mem_rd_a),
        .addr_b(mem_addr_b_fetch), .re_b(mem_re_b_fetch), .rd_b(mem_rd_b),
        .instruction(if_id_instruction), .next_byte(if_id_next_byte), .if_id_pc(if_id_pc)
    );

    reg_file RF (
        .clk(clk), .reset_in(reset_in),
        .rs1_index(if_id_rs1), .rs2_index(if_id_rs2), .rs1_data(rs1_data), .rs2_data(rs2_data),
        .reg_write(wb_reg_write), .rd_index(wb_rd_index), .rd_data(wb_rd_data),
        .sp_we(sp_we), .sp_in(sp_next), .sp_value(sp_value)
    );

    decode_stage DECODE (
        .clk(clk), .reset_in(reset_in), .instruction(if_id_instruction), .next_byte(if_id_next_byte), .if_id_pc(if_id_pc),
        .rs1_data_in(rs1_data), .rs2_data_in(rs2_data), .ccr_in(ccr_out), .id_ex_clear(id_ex_clear), .stall(hazard_stall),
        .if_id_rs1(if_id_rs1), .if_id_rs2(if_id_rs2), .id_ex_rs1_data(id_ex_rs1_data), .id_ex_rs2_data(id_ex_rs2_data),
        .id_ex_imm_or_ea(id_ex_imm_or_ea), .id_ex_pc(id_ex_pc), .id_ex_rs1(id_ex_rs1), .id_ex_rs2(id_ex_rs2), .id_ex_rd_index(id_ex_rd_index),
        .id_ex_reg_write(id_ex_reg_write), .id_ex_alu_src(id_ex_alu_src), .id_ex_alu_op(id_ex_alu_op), .id_ex_update_flags(id_ex_update_flags),
        .id_ex_restore_flags(id_ex_restore_flags), .id_ex_mem_read(id_ex_mem_read), .id_ex_mem_write(id_ex_mem_write), .id_ex_mem_to_reg(id_ex_mem_to_reg),
        .id_ex_ea_sel(id_ex_ea_sel), .id_ex_sp_adj(id_ex_sp_adj), .id_ex_is_branch(id_ex_is_branch), .id_ex_brx(id_ex_brx),
        .id_ex_is_jump(id_ex_is_jump), .id_ex_call(id_ex_call), .id_ex_ret(id_ex_ret), .id_ex_rti(id_ex_rti),
        .id_ex_is_L_format(id_ex_is_L_format), .id_ex_control_valid(id_ex_control_valid), .id_ex_io_read(id_ex_io_read), .id_ex_io_write(id_ex_io_write),
        .cu_is_L_format_out(is_L_format), .cu_pc_sel()
    );

    ex_stage EX (
        .clk(clk), .reset_in(reset_in), .id_ex_rs1_data(id_ex_rs1_data), .id_ex_rs2_data(id_ex_rs2_data), .id_ex_imm_or_ea(id_ex_imm_or_ea),
        .id_ex_pc(id_ex_pc), .id_ex_rs1(id_ex_rs1), .id_ex_rs2(id_ex_rs2), .id_ex_rd_index(id_ex_rd_index),
        .id_ex_reg_write(id_ex_reg_write), .id_ex_alu_src(id_ex_alu_src), .id_ex_alu_op(id_ex_alu_op),
        .id_ex_update_flags(id_ex_update_flags), .id_ex_restore_flags(id_ex_restore_flags), .id_ex_mem_read(id_ex_mem_read),
        .id_ex_mem_write(id_ex_mem_write), .id_ex_mem_to_reg(id_ex_mem_to_reg), .id_ex_ea_sel(id_ex_ea_sel),
        .id_ex_sp_adj(id_ex_sp_adj), .id_ex_is_branch(id_ex_is_branch), .id_ex_brx(id_ex_brx), .id_ex_is_jump(id_ex_is_jump),
        .id_ex_call(id_ex_call), .id_ex_ret(id_ex_ret), .id_ex_rti(id_ex_rti), .id_ex_control_valid(id_ex_control_valid),
        .id_ex_io_read(id_ex_io_read), .id_ex_io_write(id_ex_io_write),
        .fwd_A(fwd_A), .fwd_B(fwd_B), .ex_mem_alu_result_fwd(ex_mem_alu_result), .mem_wb_writedata(wb_rd_data),
        .restore_ccr_in(restore_ccr), .ccr_restore_data_in(ccr_restore_data), .ccr_out(ccr_out),
        .ex_branch_taken(ex_branch_taken), .ex_branch_target(branch_target), .ex_mem_alu_result(ex_mem_alu_result),
        .ex_mem_store_data(ex_mem_store_data), .ex_mem_rd_index(ex_mem_rd_index), .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_mem_read(ex_mem_mem_read), .ex_mem_mem_write(ex_mem_mem_write), .ex_mem_mem_to_reg(ex_mem_mem_to_reg),
        .ex_mem_sp_adj(ex_mem_sp_adj), .ex_mem_ea_sel(ex_mem_ea_sel), .ex_mem_ret(ex_mem_ret), .ex_mem_rti(ex_mem_rti),
        .ex_mem_is_jump(ex_mem_is_jump), .ex_mem_restore_flags(ex_mem_restore_flags), .ex_mem_io_read(ex_mem_io_read),
        .ex_mem_io_write(ex_mem_io_write), .ex_mem_call(ex_mem_call), .ex_mem_control_valid(ex_mem_control_valid)
    );

    memory_stage MEM (
        .clk(clk), .reset_in(reset_in), .ex_mem_alu_result(ex_mem_alu_result), .ex_mem_store_data(ex_mem_store_data),
        .ex_mem_rd_index(ex_mem_rd_index), .ex_mem_reg_write(ex_mem_reg_write), .ex_mem_mem_read(ex_mem_mem_read),
        .ex_mem_mem_write(ex_mem_mem_write), .ex_mem_mem_to_reg(ex_mem_mem_to_reg), .ex_mem_ea_sel(ex_mem_ea_sel),
        .ex_mem_sp_adj(ex_mem_sp_adj), .ex_mem_restore_flags(ex_mem_restore_flags), 
        .ex_mem_next_byte(id_ex_imm_or_ea), .ex_mem_rs1_data(id_ex_rs1_data),
        .mem_addr_b(mem_addr_b_mem), .mem_re_b(mem_re_b_mem), .mem_we_b(mem_we_b_mem), .mem_wd_b(mem_wd_b_mem), .mem_rd_b(mem_rd_b),
        .IN_PORT(IN_PORT), .OUT_PORT(OUT_PORT), .ex_mem_io_read(ex_mem_io_read), .ex_mem_io_write(ex_mem_io_write),
        .sp_value_in(sp_value), .sp_value_out(sp_next), .sp_write_enable(sp_we),
        .restore_ccr(restore_ccr), .ccr_restore_data(ccr_restore_data), .mem_busy(rti_busy),
        .mem_wb_data(wb_rd_data), .mem_wb_rd_index(wb_rd_index), .mem_wb_reg_write(wb_reg_write)
    );

    interrupt_controller INTR_CTRL (
        .clk(clk), .reset_in(reset_in), .intr(intr_in),
        .pc_push_data({1'b0, if_id_pc}), .ccr_push_data({4'h0, ccr_out}),
        .push_ack(mem_we_b & ~mem_portb_busy), .read_isr_valid(mem_re_a), .read_isr_data(mem_rd_a),
        .done(intr_done), .isr_value(intr_isr_value), .interrupt_flush(intr_interrupt_flush),
        .busy(intr_busy), .start_push_pc(intr_push_pc), .start_push_ccr(intr_push_ccr), .start_read_isr(intr_rd_isr)
    );

    forwarding_unit FWD_U (
        .id_ex_rs1(id_ex_rs1), .id_ex_rs2(id_ex_rs2),
        .ex_mem_rd(ex_mem_rd_index), .ex_mem_regwrite(ex_mem_reg_write),
        .mem_wb_rd(wb_rd_index), .mem_wb_regwrite(wb_reg_write),
        .fwd_A(fwd_A), .fwd_B(fwd_B)
    );

endmodule