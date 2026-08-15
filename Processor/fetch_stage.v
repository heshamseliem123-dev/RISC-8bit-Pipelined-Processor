module fetch_stage (
    input  wire        clk,
    input  wire        reset_in,
    input  wire        pc_write,      
    input  wire        if_id_write,   
    input  wire        if_id_clear,   
    input  wire [2:0]  pc_sel,        
    input  wire [6:0]  branch_target, 
    input  wire [6:0]  jump_target,   
    input  wire [6:0]  ret_addr,      
    input  wire [6:0]  isr_value,     
    input  wire        ex_branch_taken, 

    output reg  [7:0]  addr_a,
    output wire        re_a,          
    input  wire [7:0]  rd_a,

    output reg  [7:0]  addr_b,
    output wire        re_b,         
    input  wire [7:0]  rd_b,

    output reg  [7:0]  instruction,   
    output reg  [7:0]  next_byte,     
    output reg  [6:0]  if_id_pc       
);

    reg [6:0] pc;

    wire is_L_format = (rd_a[7:4] == 4'hC);
    wire [6:0] pc_increment = is_L_format ? 7'd2 : 7'd1;
    
    wire [6:0] pc_next_val = pc + pc_increment;

    assign re_a = 1'b1;
    assign re_b = 1'b1;

    always @(posedge clk or posedge reset_in) begin
        if (reset_in) begin
            pc <= 7'd0;
        end else if (pc_write) begin
           
            case (pc_sel)
                3'b000: pc <= pc_next_val;
                3'b001: pc <= branch_target;
                3'b010: pc <= jump_target;
                3'b011: pc <= ret_addr;
                3'b100: pc <= isr_value;
                default: pc <= pc_next_val;
            endcase
        end
    end

    always @(*) begin
        addr_a = pc;
        addr_b = pc + 7'd1;
    end

    always @(posedge clk or posedge reset_in) begin
        if (reset_in) begin
            instruction <= 8'h00;
            next_byte   <= 8'h00;
            if_id_pc    <= 7'd0;
        end else if (if_id_write) begin
            if (if_id_clear) begin
                instruction <= 8'h00;
                next_byte   <= 8'h00;
            end else begin
                instruction <= rd_a;
                if_id_pc    <= pc;
                next_byte   <= is_L_format ? rd_b : 8'h00;
            end
        end
    end
endmodule