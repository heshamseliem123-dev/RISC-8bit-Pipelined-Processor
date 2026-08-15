
module ex_mem_reg (
    input  wire        clk,
    input  wire        reset_in,

    input  wire [7:0]  alu_result_in,
    input  wire [7:0]  store_data_in,
    input  wire [1:0]  rd_index_in,
    input  wire        reg_write_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        mem_to_reg_in,
    input  wire [1:0]  sp_adj_in,

    input  wire [1:0]  ea_sel_in,
    input  wire        call_in,
    input  wire        ret_in,
    input  wire        rti_in,
    input  wire        is_jump_in,
    input  wire        control_valid_in,
    input  wire        restore_flags_in,  // NEW: for RTI

    // I/O control (pipelined)
    input  wire        io_read_in,
    input  wire        io_write_in,

    // ======================
    // To MEM stage
    // ======================
    output reg  [7:0]  ex_mem_alu_result,
    output reg  [7:0]  ex_mem_store_data,
    output reg  [1:0]  ex_mem_rd_index,
    output reg         ex_mem_reg_write,
    output reg         ex_mem_mem_read,
    output reg         ex_mem_mem_write,
    output reg         ex_mem_mem_to_reg,
    output reg  [1:0]  ex_mem_sp_adj,

    output reg  [1:0]  ex_mem_ea_sel,
    output reg         ex_mem_call,
    output reg         ex_mem_ret,
    output reg         ex_mem_rti,
    output reg         ex_mem_is_jump,
    output reg         ex_mem_control_valid,
    output reg         ex_mem_restore_flags,  

    // I/O outputs for MEM
    output reg         ex_mem_io_read,
    output reg         ex_mem_io_write
);

    always @(posedge clk or posedge reset_in) begin
        if (reset_in) begin

            ex_mem_alu_result      <= 8'h00;
            ex_mem_store_data      <= 8'h00;
            ex_mem_rd_index        <= 2'b00;
            ex_mem_reg_write       <= 1'b0;
            ex_mem_mem_read        <= 1'b0;
            ex_mem_mem_write       <= 1'b0;
            ex_mem_mem_to_reg      <= 1'b0;
            ex_mem_sp_adj          <= 2'b00;

            ex_mem_ea_sel          <= 2'b00;
            ex_mem_call            <= 1'b0;
            ex_mem_ret             <= 1'b0;
            ex_mem_rti             <= 1'b0;
            ex_mem_is_jump         <= 1'b0;
            ex_mem_control_valid   <= 1'b0;
            ex_mem_restore_flags   <= 1'b0; 

            ex_mem_io_read         <= 1'b0;
            ex_mem_io_write        <= 1'b0;

        end else begin
  
            ex_mem_alu_result      <= alu_result_in;
            ex_mem_store_data      <= store_data_in;
            ex_mem_rd_index        <= rd_index_in;
            ex_mem_reg_write       <= reg_write_in;
            ex_mem_mem_read        <= mem_read_in;
            ex_mem_mem_write       <= mem_write_in;
            ex_mem_mem_to_reg      <= mem_to_reg_in;
            ex_mem_sp_adj          <= sp_adj_in;

            ex_mem_ea_sel          <= ea_sel_in;
            ex_mem_call            <= call_in;
            ex_mem_ret             <= ret_in;
            ex_mem_rti             <= rti_in;
            ex_mem_is_jump         <= is_jump_in;
            ex_mem_control_valid   <= control_valid_in;
            ex_mem_restore_flags   <= restore_flags_in;  

            ex_mem_io_read         <= io_read_in;
            ex_mem_io_write        <= io_write_in;
        end
    end

endmodule