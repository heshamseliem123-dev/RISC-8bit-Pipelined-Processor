
module memory_stage (
    input  wire        clk,
    input  wire        reset_in,

    input  wire [7:0]  ex_mem_alu_result,
    input  wire [7:0]  ex_mem_store_data,
    input  wire [7:0]  ex_mem_next_byte,
    input  wire [7:0]  ex_mem_rs1_data,

    input  wire [1:0]  ex_mem_rd_index,
    input  wire        ex_mem_reg_write,
    input  wire        ex_mem_mem_read,
    input  wire        ex_mem_mem_write,
    input  wire        ex_mem_mem_to_reg,
    input  wire [1:0]  ex_mem_ea_sel,
    input  wire [1:0]  ex_mem_sp_adj,
    input  wire        ex_mem_io_read,
    input  wire        ex_mem_io_write,
    input  wire        ex_mem_restore_flags,  


    output wire [7:0]  mem_addr_b,
    output wire        mem_re_b,
    output wire        mem_we_b,
    output wire [7:0]  mem_wd_b,
    input  wire [7:0]  mem_rd_b,

  
    input  wire [7:0]  IN_PORT,
    output wire [7:0]  OUT_PORT,

 
    input  wire [7:0]  sp_value_in,
    output wire [7:0]  sp_value_out,
    output wire        sp_write_enable,

  
    output reg          restore_ccr,      
    output reg  [3:0]  ccr_restore_data, 

   
    output wire        mem_busy,       
    
    output wire [7:0]  mem_wb_data,
    output wire [1:0]  mem_wb_rd_index,
    output wire        mem_wb_reg_write
);

   
    localparam RTI_IDLE   = 2'b00;
    localparam RTI_POP_PC = 2'b01;
    localparam RTI_POP_CCR = 2'b10;

    reg [1:0] rti_state, rti_next_state;
    reg rti_reading_ccr;
    reg [7:0] sp_extra_increment;

    assign mem_busy = (rti_state != RTI_IDLE);

    always @(posedge clk or posedge reset_in) begin
        if (reset_in)
            rti_state <= RTI_IDLE;
        else
            rti_state <= rti_next_state;
    end

    always @(*) begin
        rti_next_state = rti_state;
        rti_reading_ccr = 1'b0;
        restore_ccr = 1'b0;
        sp_extra_increment = 8'h00;

        case (rti_state)
            RTI_IDLE: begin
                if (ex_mem_restore_flags) rti_next_state = RTI_POP_PC;
            end
            RTI_POP_PC: begin
                rti_next_state = RTI_POP_CCR;
            end
            RTI_POP_CCR: begin
                rti_reading_ccr = 1'b1;
                sp_extra_increment = 8'h01;
                restore_ccr = 1'b1;
                rti_next_state = RTI_IDLE;
            end
        endcase
    end

    always @(posedge clk or posedge reset_in) begin
        if (reset_in)
            ccr_restore_data <= 4'h0;
        else if (rti_reading_ccr)
            ccr_restore_data <= mem_rd_b[3:0];
    end


    wire [7:0] sp_addr_used;
    wire [7:0] sp_next_normal;
    wire sp_we_normal;

    sp_update SPU (
        .sp_adj          (ex_mem_sp_adj),
        .sp_current      (sp_value_in),
        .sp_next         (sp_next_normal),
        .sp_addr_used    (sp_addr_used),
        .sp_write_enable (sp_we_normal)
    );

    assign sp_value_out = (rti_reading_ccr) ? (sp_value_in + sp_extra_increment) : sp_next_normal;
    assign sp_write_enable = sp_we_normal | rti_reading_ccr;


    wire [7:0] mem_addr_b_normal;

    mem_addr_mux ADDR_MUX (
        .ea_sel     (ex_mem_ea_sel),
        .alu_result (ex_mem_alu_result),
        .rs1_data   (ex_mem_rs1_data),
        .next_byte  (ex_mem_next_byte),
        .sp_addr    (rti_reading_ccr ? (sp_value_in + sp_extra_increment) : sp_addr_used),
        .addr_out   (mem_addr_b_normal)
    );

    assign mem_addr_b = mem_addr_b_normal;
    assign mem_wd_b   = ex_mem_store_data;

    assign mem_re_b = (ex_mem_mem_read & ~ex_mem_io_read) | rti_reading_ccr;
    assign mem_we_b = ex_mem_mem_write & ~ex_mem_io_write & ~rti_reading_ccr;

    // -------------------------
    // OUT port (I/O write)
    // -------------------------
    reg [7:0] out_port_reg;
    always @(posedge clk or posedge reset_in) begin
        if (reset_in)
            out_port_reg <= 8'h00;
        else if (ex_mem_io_write)
            out_port_reg <= ex_mem_store_data;
    end
    assign OUT_PORT = out_port_reg;

    // -------------------------
    // Memory read register
    // -------------------------
    
    reg [7:0] mem_data_reg;
    always @(posedge clk or posedge reset_in) begin
        if (reset_in) begin
            mem_data_reg <= 8'h00;
        end else if (mem_re_b) begin
            if (ex_mem_io_read)
                mem_data_reg <= IN_PORT;
            else
                mem_data_reg <= mem_rd_b;
        end
    end


    wire [7:0] wb_data_internal; 

    wb_mux WB (
        .io_read     (ex_mem_io_read),
        .mem_to_reg  (ex_mem_mem_to_reg),
        .alu_result  (ex_mem_alu_result),
        .mem_data    (mem_data_reg),
        .io_data     (IN_PORT),
        .wb_data     (wb_data_internal) 
    );

  
    mem_wb_reg MEM_WB (
        .clk           (clk),
        .reset_in      (reset_in),
        .wb_data_in    (wb_data_internal), 
        .rd_index_in   (ex_mem_rd_index),
        .reg_write_in  (ex_mem_reg_write),
        .wb_data_out   (mem_wb_data),      
        .rd_index_out  (mem_wb_rd_index),
        .reg_write_out (mem_wb_reg_write)
    );

endmodule