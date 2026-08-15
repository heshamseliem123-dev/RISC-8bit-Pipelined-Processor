
module wb_mux (
    input  wire        io_read,
    input  wire        mem_to_reg,
    input  wire [7:0]  alu_result,
    input  wire [7:0]  mem_data,
    input  wire [7:0]  io_data,
    output reg  [7:0]  wb_data
);

always @(*) begin
    if (io_read)
        wb_data = io_data;
    else if (mem_to_reg)
        wb_data = mem_data;
    else
        wb_data = alu_result;
end

endmodule
