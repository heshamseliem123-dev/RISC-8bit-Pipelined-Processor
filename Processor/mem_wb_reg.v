
module mem_wb_reg (
    input  wire        clk,
    input  wire        reset_in,
    input  wire [7:0]  wb_data_in,
    input  wire [1:0]  rd_index_in,
    input  wire        reg_write_in,
    output reg  [7:0]  wb_data_out,
    output reg  [1:0]  rd_index_out,
    output reg         reg_write_out
);

always @(posedge clk or posedge reset_in) begin
    if (reset_in) begin
        wb_data_out   <= 8'h00;
        rd_index_out  <= 2'b00;
        reg_write_out <= 1'b0;
    end else begin
        wb_data_out   <= wb_data_in;
        rd_index_out  <= rd_index_in;
        reg_write_out <= reg_write_in;
    end
end

endmodule
