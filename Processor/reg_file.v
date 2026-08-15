
module reg_file (
    input  wire        clk,
    input  wire        reset_in,
    input  wire [1:0]  rs1_index,
    input  wire [1:0]  rs2_index,
    output wire [7:0]  rs1_data,
    output wire [7:0]  rs2_data,
    input  wire        reg_write,
    input  wire [1:0]  rd_index,
    input  wire [7:0]  rd_data,
    input  wire        sp_we,
    input  wire [7:0]  sp_in,
    output wire [7:0]  sp_value
);
    reg [7:0] regs [0:3];

    assign rs1_data = regs[rs1_index];
    assign rs2_data = regs[rs2_index];
    assign sp_value = regs[3];

    always @(posedge clk or posedge reset_in) begin
        if (reset_in) begin
            regs[0] <= 8'h00;
            regs[1] <= 8'h00;
            regs[2] <= 8'h00;
            regs[3] <= 8'hFF;  
        end else begin
          
            if (sp_we) begin
                regs[3] <= sp_in;
            end else if (reg_write) begin
             
                regs[rd_index] <= rd_data;
            end
        end
    end
endmodule