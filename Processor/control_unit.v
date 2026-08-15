module control_unit(
   input [7:0] instruction,
   input [7:0] next_byte,
   input [3:0] ccr_in,
   input reset_in,
   output reg reg_write,
   output reg  [1:0] rd_index,    
   output reg  alu_src,      
   output reg  update_flags,
   output reg  restore_flags,  
   output reg mem_read,
   output reg mem_write,
   output reg mem_to_reg,   
   output reg [1:0] ea_sel, 
   output reg [1:0] sp_adj,  

   output reg is_branch,
   output reg [1:0] brx,  
   output reg is_jump,
   output reg call,
   output reg ret,
   output reg  rti,
   output reg [2:0] pc_sel,
   output reg io_read,
   output reg io_write,
   output reg is_L_format,
   output reg [3:0] alu_op,
   output reg control_valid
); 

localparam PC_NEXT  = 3'b000;
localparam PC_BRANCH = 3'b001;
localparam PC_JUMP  = 3'b010;
localparam PC_RET   = 3'b011;
localparam PC_ISR   = 3'b100;
localparam ALU_NOP  = 4'd0;
localparam ALU_ADD  = 4'd1;
localparam ALU_SUB  = 4'd2;
localparam ALU_AND  = 4'd3;
localparam ALU_OR   = 4'd4;
localparam ALU_PASS = 4'd5;
localparam ALU_NOT  = 4'd6;
localparam ALU_NEG  = 4'd7;
localparam ALU_INC  = 4'd8;
localparam ALU_DEC  = 4'd9;
localparam ALU_RLC  = 4'd10;
localparam ALU_RRC  = 4'd11;
localparam ALU_SETC = 4'd12;
localparam ALU_CLRC = 4'd13;


wire [3:0] opcode = instruction[7:4];
wire [1:0] ra     = instruction[3:2];
wire [1:0] rb     = instruction[1:0];

always @(*) begin
   reg_write = 1'b0;
   rd_index = 2'b00;
   alu_op = ALU_NOP;
   alu_src = 1'b0;
   update_flags  = 1'b0;
   restore_flags = 1'b0;  
   mem_read  = 1'b0;
   mem_write = 1'b0;
   mem_to_reg= 1'b0;
   ea_sel = 2'b00;
   sp_adj = 2'b00;
   
   is_branch  = 1'b0;
   brx  = ra;
   is_jump = 1'b0;
   call= 1'b0;
   ret = 1'b0;
   rti = 1'b0;
   pc_sel= PC_NEXT;
   io_read = 1'b0;
   io_write= 1'b0;
   is_L_format   = 1'b0;
   control_valid = 1'b1;

   case (opcode) 
   4'h0: begin 
      
   end

   
   4'h1: begin  
      reg_write = 1'b1;
      rd_index  = ra;
      alu_op    = ALU_PASS;
      alu_src   = 1'b0;
   end

   4'h2: begin  
      reg_write = 1'b1; 
      rd_index = ra;
      alu_op = ALU_ADD;
      alu_src = 1'b0;
      
      update_flags = 1'b1; 
   end

   4'h3: begin  
      reg_write = 1'b1;
      rd_index = ra;
      alu_op = ALU_SUB;
      alu_src = 1'b0;

      update_flags = 1'b1;
   end

   4'h4: begin 
      reg_write = 1'b1;
      rd_index = ra;
      alu_op= ALU_AND;
      alu_src = 1'b0;

      update_flags = 1'b1;
   end

   4'h5: begin  
      reg_write = 1'b1;
      rd_index = ra;
      alu_op  = ALU_OR;
      alu_src = 1'b0;

      //update flags (Z,N)
      update_flags = 1'b1;
   end

   4'h6: begin
      case(ra)
         2'b00: begin 
            reg_write = 1'b1;
            rd_index = rb;
            alu_op = ALU_RLC;

            update_flags = 1'b1;
         end

         2'b01: begin 
            reg_write = 1'b1;
            rd_index = rb;
            alu_op = ALU_RRC;

            update_flags = 1'b1;
         end

         2'b10: begin 
            alu_op = ALU_SETC;
            update_flags = 1'b1;
         end

         2'b11: begin 
            alu_op = ALU_CLRC;
            update_flags = 1'b1;
         end
      endcase
   end

   4'h7: begin 
      case (ra)
         2'b00: begin 
            mem_write = 1'b1;
            ea_sel = 2'b10;   
            sp_adj = 2'b01;   
         end

         2'b01: begin 
            mem_read   = 1'b1;
            ea_sel     = 2'b10;  
            sp_adj     = 2'b10;  
            reg_write  = 1'b1;
            rd_index   = rb;
            mem_to_reg = 1'b1;
         end

         2'b10: begin 
            io_write = 1'b1;
         end

         2'b11: begin 
            io_read   = 1'b1;
            reg_write = 1'b1;
            rd_index  = rb;
            mem_to_reg = 1'b1; 
         end
      endcase
   end

   4'h8: begin 
      case (ra)
         2'b00: begin 
            reg_write = 1'b1;
            rd_index  = rb;
            alu_op    = ALU_NOT;

            update_flags = 1'b1;
         end

         2'b01: begin 
            reg_write = 1'b1;
            rd_index  = rb;
            alu_op   = ALU_NEG;

            update_flags = 1'b1;
         end

         2'b10: begin 
            reg_write = 1'b1;
            rd_index  = rb;
            alu_op    = ALU_INC;

            update_flags = 1'b1;
         end

         2'b11: begin 
            reg_write = 1'b1;
            rd_index  = rb;
            alu_op   = ALU_DEC;

            update_flags = 1'b1;
         end
      endcase
   end

   4'h9: begin 
      is_branch = 1'b1;
      brx       = ra;      
      pc_sel    = PC_BRANCH;
   end

   4'hA: begin 
      is_branch = 1'b1;
      brx       = ra;
      pc_sel    = PC_BRANCH;
      reg_write = 1'b1;
      rd_index  = ra;
      alu_op    = ALU_DEC;
   end

   4'hB: begin
      case (ra)
         2'b00: begin 
            is_jump = 1'b1;
            pc_sel  = PC_JUMP;
         end
         
         2'b01: begin 
            call    = 1'b1;
            sp_adj  = 2'b01;   
            is_jump = 1'b1;
            pc_sel  = PC_JUMP;
         end
         
         2'b10: begin 
            ret     = 1'b1;
            sp_adj  = 2'b10;   
            mem_read = 1'b1;   
            ea_sel   = 2'b10;  
            pc_sel   = PC_RET;
         end
         
         2'b11: begin 
            rti     = 1'b1;
            sp_adj  = 2'b10;      
            mem_read = 1'b1;      
            ea_sel   = 2'b10;     
            pc_sel   = PC_RET;
            restore_flags = 1'b1; 
			end 
      endcase
   end

   4'hC: begin 
      is_L_format = 1'b1; 
      case (ra)
         2'b00: begin 
            reg_write  = 1'b1;
            rd_index   = rb;
            alu_src    = 1'b1;  
            alu_op     = ALU_PASS;
            mem_to_reg = 1'b0;
         end
         
         2'b01: begin
            mem_read   = 1'b1;
            reg_write  = 1'b1;
            rd_index   = rb;
            mem_to_reg = 1'b1;
            ea_sel     = 2'b00;  
         end
         
         2'b10: begin 
            mem_write = 1'b1;
            ea_sel    = 2'b00;   
         end
      endcase
   end

   4'hD: begin 
      mem_read   = 1'b1;
      reg_write  = 1'b1;
      rd_index   = rb;
      mem_to_reg = 1'b1;
      ea_sel     = 2'b01; 
   end

   4'hE: begin 
      mem_write = 1'b1;
      ea_sel    = 2'b01;   
   end

   default: begin
      control_valid = 1'b0; 
   end
   endcase
end

endmodule