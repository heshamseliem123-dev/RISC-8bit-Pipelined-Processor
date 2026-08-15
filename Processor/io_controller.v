
module io_controller (
    input  wire        clk,
    input  wire        reset_in,
    input  wire        io_read,
    input  wire        io_write,
    input  wire [7:0]  rb_data,
    input  wire [7:0]  IN_PORT,
    output reg  [7:0]  OUT_PORT,
    output wire [7:0]  io_data
);

always @(posedge clk or posedge reset_in) begin
    if (reset_in)
        OUT_PORT <= 8'h00;
    else if (io_write)
        OUT_PORT <= rb_data;
end

assign io_data = io_read ? IN_PORT : 8'h00;

endmodule
