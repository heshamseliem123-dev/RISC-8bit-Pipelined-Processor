
module ccr_reg (
    input  wire       clk,
    input  wire       reset_in,
    
    input  wire       update_flags,
    input  wire       z_in,
    input  wire       n_in,
    input  wire       c_in,
    input  wire       v_in,
    
    input  wire       restore_flags,
    input  wire [3:0] ccr_restore,
    
    output reg  [3:0] ccr_out   
);

    always @(posedge clk or posedge reset_in) begin
        if (reset_in) begin
            ccr_out <= 4'b0000;
        end else if (restore_flags) begin
         
            ccr_out <= ccr_restore;
        end else if (update_flags) begin
          
            ccr_out <= {v_in, c_in, n_in, z_in};
        end
    end
endmodule