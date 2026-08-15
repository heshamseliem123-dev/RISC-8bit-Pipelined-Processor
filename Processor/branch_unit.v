
module branch_unit (
    input  wire        is_branch,
    input  wire [1:0]  brx,
    input  wire        is_loop,
    input  wire [3:0]  ccr_in,   // {Z,N,C,V}
    input  wire        alu_z,
    output reg         branch_taken
);

    wire flag_Z = ccr_in[0];
    wire flag_N = ccr_in[1];
    wire flag_C = ccr_in[2];
    wire flag_V = ccr_in[3];

    reg cond_flag;

    always @(*) begin
        case (brx)
            2'b00: cond_flag = flag_Z;
            2'b01: cond_flag = flag_N;
            2'b10: cond_flag = flag_C;
            2'b11: cond_flag = flag_V;
            default: cond_flag = 1'b0;
        endcase
    end

    always @(*) begin
        if (is_branch) begin
            if (is_loop)
                branch_taken = ~alu_z;      
            else
                branch_taken = cond_flag;   // JZ/JN/JC/JV
        end else begin
            branch_taken = 1'b0;
        end
    end

endmodule
