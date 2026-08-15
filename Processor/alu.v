
module ALU (
    input  wire [3:0]  alu_op,
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    input  wire        cin,
    output reg  [7:0]  result,
    output wire        z,
    output wire        n,
    output reg         c,
    output reg         v
);

    localparam ALU_NOP  = 4'd0, ALU_ADD  = 4'd1, ALU_SUB  = 4'd2,
               ALU_AND  = 4'd3, ALU_OR   = 4'd4, ALU_PASS = 4'd5,
               ALU_NOT  = 4'd6, ALU_NEG  = 4'd7, ALU_INC  = 4'd8,
               ALU_DEC  = 4'd9, ALU_RLC  = 4'd10, ALU_RRC = 4'd11,
               ALU_SETC = 4'd12, ALU_CLRC = 4'd13;

    reg [8:0] tmp;

    assign z = (result == 8'h00);
    assign n = result[7];

    always @(*) begin
   
        result = b; 
        c = cin;
        v = 1'b0;
        tmp = 9'b0;

        case (alu_op)
            ALU_ADD: begin
                tmp    = {1'b0, a} + {1'b0, b};
                result = tmp[7:0];
                c      = tmp[8];
                v      = (a[7] == b[7] && result[7] != a[7]);
            end
            ALU_SUB: begin
                tmp    = {1'b0, a} - {1'b0, b};
                result = tmp[7:0];
                c      = !tmp[8]; 
                v      = (a[7] != b[7] && result[7] != a[7]);
            end
            ALU_AND:  result = a & b;
            ALU_OR:   result = a | b;
            ALU_NOT:  result = ~b;
            ALU_NEG: begin
                tmp    = 9'h000 - {1'b0, b};
                result = tmp[7:0];
                c      = (b == 8'h00); 
                v      = (b == 8'h80);
            end
            ALU_INC: begin
                tmp = {1'b0, b} + 1;
                result = tmp[7:0];
                c = tmp[8];
                v = (b[7] == 0 && result[7] == 1);
            end
            ALU_DEC: begin
                tmp = {1'b0, b} - 1;
                result = tmp[7:0];
                c = (b != 8'h00);
                v = (b[7] == 1 && result[7] == 0);
            end
            ALU_RLC: begin
                c = b[7];
                result = {b[6:0], cin};
            end
            ALU_RRC: begin
                c = b[0];
                result = {cin, b[7:1]};
            end
            ALU_SETC: begin
                c = 1'b1;
                result = b; 
            end
            ALU_CLRC: begin
                c = 1'b0;
                result = b;
            end
            default: result = b;
        endcase
    end
endmodule