
module memory_dualport (
    input  wire        clk,
    input  wire [7:0]  addr_a,  
    input  wire        re_a,
    output wire [7:0]  rd_a,

    input  wire [7:0]  addr_b,   
    input  wire        re_b,
    input  wire        we_b,
    input  wire [7:0]  wd_b,
    output wire [7:0]  rd_b
);

    reg [7:0] mem [0:255];

assign rd_a = (re_a) ? mem[addr_a] : 8'h00;

    assign rd_b = (re_b) ? mem[addr_b] : 8'h00;

    always @(posedge clk) begin
        if (we_b) begin
            mem[addr_b] <= wd_b;
        end
    end

endmodule
