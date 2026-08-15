`timescale 1ns/1ps


module tb_cpu_modular;

    reg         clk;
    reg         reset_in;
    reg         intr_in;
    reg  [7:0]  IN_PORT;
    wire [7:0]  OUT_PORT;

    integer test_count;
    integer pass_count;
    integer fail_count;

    parameter TEST_GROUP_1 = 1;
    parameter TEST_GROUP_2 = 1;
    parameter TEST_GROUP_3 = 1;
    parameter TEST_GROUP_4 = 1;
    parameter TEST_GROUP_5 = 1; // JC (branch on C)
    parameter TEST_GROUP_6 = 1; // JMP
    parameter TEST_GROUP_7 = 1; // CALL/RET
    parameter TEST_GROUP_8 = 1;
    parameter TEST_GROUP_9 = 1;
    parameter TEST_GROUP_10 = 1;
    parameter TEST_GROUP_11 = 1;




    // Instance of CPU
    cpu_tob DUT (
        .clk      (clk),
        .reset_in (reset_in),
        .intr_in  (intr_in),
        .IN_PORT  (IN_PORT),
        .OUT_PORT (OUT_PORT)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $display("========================================");
        $display("  CPU Testbench - v5 MAX SPEED");
        $display("  Sequential Execution - No Bubbles");
        $display("========================================");

        test_count = 0;
        pass_count = 0;
        fail_count = 0;

        reset_in = 1;
        intr_in  = 0;
        IN_PORT  = 8'h00;

        #20;
        reset_in = 0;
        run_cycles(6);

        if (TEST_GROUP_1) test_group_1_basic_alu();
        if (TEST_GROUP_2) test_group_2_shifts_flags();
        if (TEST_GROUP_3) test_group_3_loop_only();
        if (TEST_GROUP_4) test_group_4_stack_and_io();
        if (TEST_GROUP_5) test_group_5_branch_jc();
        if (TEST_GROUP_6) test_group_6_jmp();
        if (TEST_GROUP_7) test_group_7_call_ret();
        if (TEST_GROUP_8)  test_group_8_jz();
        if (TEST_GROUP_9) test_group_9_jn();
        if (TEST_GROUP_10) test_group_10_jv();
        if (TEST_GROUP_11) test_group_11_rti_standalone();




        #100;
        print_final_report();
        $finish;
    end

    // ============================
    // TEST GROUP 1: Sequential Addressing
    // ============================
    task test_group_1_basic_alu;
        begin
            print_group_header("GROUP 1: Basic ALU Operations");

            init_memory_group1();
            reset_cpu();

            // Program layout (Sequential):
            // 0x00: LDM R0,#5  (PC goes to 2)
            // 0x02: MOV R1,R0  (PC goes to 3)
            // 0x03: ADD R0,R1  (PC goes to 4)
            // 0x04: SUB R0,R1  (PC goes to 5)
            // 0x05: LDM R2,#15 (PC goes to 7)
            // 0x07: AND R2,R1  (PC goes to 8)
            // 0x08: LDM R2,#10 (PC goes to 10)
            // 0x0A: OR R2,R1   (PC goes to 11)
            // 0x0B: NOT R0     (PC goes to 12)
            // 0x0C: NEG R1     (PC goes to 13)

            wait_pc(8'h02); run_cycles(3); 
            check_reg(0, 8'h05, "LDM R0,#5");

            wait_pc(8'h03); run_cycles(3); 
            check_reg(1, 8'h05, "MOV R1,R0");

            wait_pc(8'h04); run_cycles(3); 
            check_reg(0, 8'h0A, "ADD R0,R1 = 10");

            wait_pc(8'h05); run_cycles(3); 
            check_reg(0, 8'h05, "SUB R0,R1 = 5");

            wait_pc(8'h07); run_cycles(3); 
            check_reg(2, 8'h0F, "LDM R2,#15");

            wait_pc(8'h08); run_cycles(3); 
            check_reg(2, 8'h05, "AND R2,R1 = 5");

            wait_pc(8'h0A); run_cycles(3); 
            check_reg(2, 8'h0A, "LDM R2,#10");

            wait_pc(8'h0B); run_cycles(3); 
            check_reg(2, 8'h0F, "OR R2,R1 = 15");

            wait_pc(8'h0C); run_cycles(3); 
            check_reg(0, 8'hFA, "NOT R0 = 0xFA");

            run_cycles(5);
            check_reg(1, 8'hFB, "NEG R1 = 0xFB");

            print_group_footer();
        end
    endtask

    // ============================
    // TEST GROUP 2
    // ============================

    task test_group_2_shifts_flags;
        begin
            print_group_header("GROUP 2: Shifts & Flags");

            init_memory_group2();
            reset_cpu();

            // Program:
            // 0x00: LDM R0,#5 
            // 0x02: INC R0    
            // 0x03: DEC R0    
            // 0x04: SETC      
            // 0x05: LDM R1,#5 
            // 0x07: RLC R1    
            // 0x08: CLRC      
            // 0x09: RRC R1    

            wait_pc(8'h02); run_cycles(3);
            check_reg(0, 8'h05, "LDM R0,#5");

            wait_pc(8'h03); run_cycles(3);
            check_reg(0, 8'h06, "INC R0 = 6");

            wait_pc(8'h04); run_cycles(3);
            check_reg(0, 8'h05, "DEC R0 = 5");

            // --- تعديل SETC ---
            wait_pc(8'h05); 
            run_cycles(6); 
            check_flag_c(1, "SETC");

            wait_pc(8'h07); run_cycles(3);
            check_reg(1, 8'h05, "LDM R1,#5");

            wait_pc(8'h08); run_cycles(3);
            check_reg(1, 8'h0B, "RLC R1 = 0x0B (Carry was 1)");

          
            wait_pc(8'h09); 
            run_cycles(1); 
            check_flag_c(0, "CLRC");

            run_cycles(4); 
            check_reg(1, 8'h05, "RRC R1 = 0x05");
            print_group_footer();
        end
    endtask
    // ============================
    // GROUP 3: LOOP + NOP padding
    // ============================
    task test_group_3_loop_only;
        integer i;
        integer pcw;
        begin
            print_group_header("GROUP 3: LOOP");

            // clear mem
            for (i = 0; i < 256; i = i + 1) DUT.UNIFIED_MEM.mem[i] = 8'h00;
            pcw = 0;

            // Program:
            // 0: LDM R1,#3
            // 2: LDM R2,#40
            // 4: LOOP R1,R2
            // 5: LDM R3,#33 (after loop)
            DUT.UNIFIED_MEM.mem[pcw] = 8'hC1; pcw=pcw+1; // LDM R1
            DUT.UNIFIED_MEM.mem[pcw] = 8'h03; pcw=pcw+1;

            DUT.UNIFIED_MEM.mem[pcw] = 8'hC2; pcw=pcw+1; // LDM R2
            DUT.UNIFIED_MEM.mem[pcw] = 8'd40; pcw=pcw+1;

            DUT.UNIFIED_MEM.mem[pcw] = 8'hA6; pcw=pcw+1; // LOOP ra=R1(01), rb=R2(10) => {A,01,10}=A6

            DUT.UNIFIED_MEM.mem[pcw] = 8'hC3; pcw=pcw+1; // LDM R3
            DUT.UNIFIED_MEM.mem[pcw] = 8'h33; pcw=pcw+1;

            // pad until address 40 with NOPs
            while (pcw < 40) begin
                DUT.UNIFIED_MEM.mem[pcw] = 8'h00; // NOP
                pcw = pcw + 1;
            end
            DUT.UNIFIED_MEM.mem[pcw] = 8'h00; // NOP body

            reset_cpu();
            run_cycles(300);

            check_reg(2'd3, 8'h33, "LOOP ends then LDM R3,#33");

            print_group_footer();
        end
    endtask

    task test_group_4_stack_and_io;
        integer i;
        integer pcw;
        begin
            print_group_header("GROUP 4: STACK + IO");

            for (i = 0; i < 256; i = i + 1) DUT.UNIFIED_MEM.mem[i] = 8'h00;
            pcw = 0;

            // R1=A5
            DUT.UNIFIED_MEM.mem[pcw] = 8'hC1; pcw=pcw+1; // LDM R1
            DUT.UNIFIED_MEM.mem[pcw] = 8'hA5; pcw=pcw+1;

            // PUSH R1: opcode 7, ra=00, rb=01 => 0x71
            DUT.UNIFIED_MEM.mem[pcw] = 8'h71; pcw=pcw+1;

            // R1=00
            DUT.UNIFIED_MEM.mem[pcw] = 8'hC1; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw] = 8'h00; pcw=pcw+1;

            // POP R1: opcode 7, ra=01, rb=01 => 0x75
            DUT.UNIFIED_MEM.mem[pcw] = 8'h75; pcw=pcw+1;

            // IN R2: opcode 7, ra=11, rb=10 => 0x7E
            DUT.UNIFIED_MEM.mem[pcw] = 8'h7E; pcw=pcw+1;

            // OUT R2: opcode 7, ra=10, rb=10 => 0x7A
            DUT.UNIFIED_MEM.mem[pcw] = 8'h7A; pcw=pcw+1;

            reset_cpu();

            // set input before IN executes
            IN_PORT = 8'h3C;

            run_cycles(300);

            check_reg(2'd1, 8'hA5, "PUSH/POP restores R1=0xA5");

            // OUT check
            test_count = test_count + 1;
            if (OUT_PORT == 8'h3C) begin
                $display("  ✓ Test %0d PASS: OUT_PORT=0x3C", test_count);
                pass_count = pass_count + 1;
            end else begin
                $display("  ✗ Test %0d FAIL: OUT_PORT=0x%02h expected 0x3C", test_count, OUT_PORT);
                fail_count = fail_count + 1;
            end

            print_group_footer();
        end
    endtask


    // ============================
    // GROUP 5
    // ============================ 
    task test_group_5_branch_jc;
        integer i;
        integer pcw;
        integer target;
        begin
            print_group_header("GROUP 5: Branch (JC)");

            for (i = 0; i < 256; i = i + 1) DUT.UNIFIED_MEM.mem[i] = 8'h00;
            pcw = 0;

            target = 8'h20;

            // SETC  (opcode 6, ra=10, rb=00 => 0x68)
            DUT.UNIFIED_MEM.mem[pcw] = 8'h68; pcw=pcw+1;

            // LDM R2, #target
            DUT.UNIFIED_MEM.mem[pcw] = 8'hC2; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw] = target[7:0]; pcw=pcw+1;

            // JC R2  (opcode 9, ra=10 (C), rb=10 (R2) => 0x9A)
            DUT.UNIFIED_MEM.mem[pcw] = 8'h9A; pcw=pcw+1;

            // This should be FLUSHED if JC taken:
            // LDM R0, #11
            DUT.UNIFIED_MEM.mem[pcw] = 8'hC0; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw] = 8'h11; pcw=pcw+1;

            // pad until target with NOPs
            while (pcw < target) begin
                DUT.UNIFIED_MEM.mem[pcw] = 8'h00;
                pcw = pcw + 1;
            end

            // target: LDM R0, #AA
            DUT.UNIFIED_MEM.mem[pcw] = 8'hC0; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw] = 8'hAA; pcw=pcw+1;

            reset_cpu();
            run_cycles(400);

            check_reg(2'd0, 8'hAA, "JC taken -> R0 should be 0xAA (flush 0x11)");

            print_group_footer();
        end
    endtask



    // ============================
    // GROUP 6
    // ============================ 

    task test_group_6_jmp;
        integer i;
        integer pcw;
        integer target;
        begin
            print_group_header("GROUP 6: JMP");

            for (i = 0; i < 256; i = i + 1) DUT.UNIFIED_MEM.mem[i] = 8'h00;
            pcw = 0;

            target = 8'h20;

            // LDM R2, #target
            DUT.UNIFIED_MEM.mem[pcw] = 8'hC2; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw] = target[7:0]; pcw=pcw+1;

            // JMP R2 (opcode B, ra=00, rb=10 => 0xB2)
            DUT.UNIFIED_MEM.mem[pcw] = 8'hB2; pcw=pcw+1;

            // should be skipped
            DUT.UNIFIED_MEM.mem[pcw] = 8'hC0; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw] = 8'h11; pcw=pcw+1;

            // pad to target
            while (pcw < target) begin
                DUT.UNIFIED_MEM.mem[pcw] = 8'h00;
                pcw = pcw + 1;
            end

            // target: LDM R0,#55
            DUT.UNIFIED_MEM.mem[pcw] = 8'hC0; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw] = 8'h55; pcw=pcw+1;

            reset_cpu();
            run_cycles(400);

            check_reg(2'd0, 8'h55, "JMP taken -> R0 should be 0x55");

            print_group_footer();
        end
    endtask



    // ============================
    // GROUP 7
    // ============================ 
    task test_group_7_call_ret;
        integer i;
        integer pcw;
        integer sub;
        begin
            print_group_header("GROUP 7: CALL/RET");

            for (i = 0; i < 256; i = i + 1) DUT.UNIFIED_MEM.mem[i] = 8'h00;
            pcw = 0;

            sub = 8'h40;

            // main:
            // LDM R2, #sub
            DUT.UNIFIED_MEM.mem[pcw] = 8'hC2; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw] = sub[7:0]; pcw=pcw+1;

            // CALL R2 (opcode B, ra=01, rb=10 => 0xB6)
            DUT.UNIFIED_MEM.mem[pcw] = 8'hB6; pcw=pcw+1;

            // after return: LDM R0, #11
            DUT.UNIFIED_MEM.mem[pcw] = 8'hC0; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw] = 8'h11; pcw=pcw+1;

            // pad to sub
            while (pcw < sub) begin
                DUT.UNIFIED_MEM.mem[pcw] = 8'h00;
                pcw = pcw + 1;
            end

            // subroutine @0x40:
            // LDM R0,#99
            DUT.UNIFIED_MEM.mem[pcw] = 8'hC0; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw] = 8'h99; pcw=pcw+1;

            // RET (opcode B, ra=10, rb=00 => 0xB8)
            DUT.UNIFIED_MEM.mem[pcw] = 8'hB8; pcw=pcw+1;

            reset_cpu();
            run_cycles(600);

            // If RET worked, main overwrote R0 with 0x11
            check_reg(2'd0, 8'h11, "CALL sub then RET -> back to main (R0=0x11)");

            print_group_footer();
        end
    endtask


    // ============================
    // GROUP 8: Branch (JZ)
    // ============================

    task test_group_8_jz;
        integer i;
        integer pcw;
        integer target;
        begin
            print_group_header("GROUP 8: JZ (Z flag + flush)");

            for (i=0;i<256;i=i+1) DUT.UNIFIED_MEM.mem[i]=8'h00;
            pcw=0;
            target = 8'h30;

            // LDM R0,#05
            DUT.UNIFIED_MEM.mem[pcw]=8'hC0; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw]=8'h05; pcw=pcw+1;

            // MOV R1,R0  (0x14)
            DUT.UNIFIED_MEM.mem[pcw]=8'h14; pcw=pcw+1;

            // SUB R0,R1  => 0 => Z=1  (opcode3 ra=00 rb=01 => 0x31)
            DUT.UNIFIED_MEM.mem[pcw]=8'h31; pcw=pcw+1;

            // give pipeline a couple cycles then check Z
            reset_cpu();
            run_cycles(40);
            check_flag_z(1, "Z should be 1 after SUB result=0");

            // rebuild same program but with branch target now (fresh run)
            for (i=0;i<256;i=i+1) DUT.UNIFIED_MEM.mem[i]=8'h00;
            pcw=0;

            DUT.UNIFIED_MEM.mem[pcw]=8'hC0; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw]=8'h05; pcw=pcw+1;

            DUT.UNIFIED_MEM.mem[pcw]=8'h14; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw]=8'h31; pcw=pcw+1;

            // LDM R2,#target
            DUT.UNIFIED_MEM.mem[pcw]=8'hC2; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw]=target[7:0]; pcw=pcw+1;

            // JZ R2 : opcode 9, ra=00(Z), rb=10(R2) => 0x92
            DUT.UNIFIED_MEM.mem[pcw]=8'h92; pcw=pcw+1;

            // should be flushed
            DUT.UNIFIED_MEM.mem[pcw]=8'hC3; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw]=8'h11; pcw=pcw+1;

            while (pcw < target) begin
                DUT.UNIFIED_MEM.mem[pcw]=8'h00; pcw=pcw+1;
            end

            // target: LDM R3,#AA
            DUT.UNIFIED_MEM.mem[pcw]=8'hC3; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw]=8'hAA; pcw=pcw+1;

            reset_cpu();
            run_cycles(500);

            check_reg(2'd3, 8'hAA, "JZ taken -> R3=0xAA (flush 0x11)");

            print_group_footer();
        end
    endtask


    // ============================
    // GROUP 9: Branch (JN)
    // ============================
    task test_group_9_jn;
        integer i;
        integer pcw;
        integer target;
        begin
            print_group_header("GROUP 9: JN (N flag + flush)");

            for (i=0;i<256;i=i+1) DUT.UNIFIED_MEM.mem[i]=8'h00;
            pcw=0;
            target=8'h34;

            // LDM R0,#01
            DUT.UNIFIED_MEM.mem[pcw]=8'hC0; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw]=8'h01; pcw=pcw+1;

            // NEG R0 => 0xFF -> N=1  (8, ra=01 rb=00 => 0x84)
            DUT.UNIFIED_MEM.mem[pcw]=8'h84; pcw=pcw+1;

            reset_cpu();
            run_cycles(40);
            check_flag_n(1, "N should be 1 after NEG (result 0xFF)");

            // rebuild with branch
            for (i=0;i<256;i=i+1) DUT.UNIFIED_MEM.mem[i]=8'h00;
            pcw=0;

            DUT.UNIFIED_MEM.mem[pcw]=8'hC0; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw]=8'h01; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw]=8'h84; pcw=pcw+1;

            // LDM R2,#target
            DUT.UNIFIED_MEM.mem[pcw]=8'hC2; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw]=target[7:0]; pcw=pcw+1;

            // JN R2 : opcode 9, ra=01(N), rb=10(R2) => 0x96
            DUT.UNIFIED_MEM.mem[pcw]=8'h96; pcw=pcw+1;

            // flushed
            DUT.UNIFIED_MEM.mem[pcw]=8'hC1; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw]=8'h11; pcw=pcw+1;

            while (pcw < target) begin
                DUT.UNIFIED_MEM.mem[pcw]=8'h00; pcw=pcw+1;
            end

            // target: LDM R1,#AA
            DUT.UNIFIED_MEM.mem[pcw]=8'hC1; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw]=8'hAA; pcw=pcw+1;

            reset_cpu();
            run_cycles(500);

            check_reg(2'd1, 8'hAA, "JN taken -> R1=0xAA (flush 0x11)");

            print_group_footer();
        end
    endtask


    // ============================
    // GROUP 10: Branch (JV)
    // ============================
    task test_group_10_jv;
        integer i;
        integer pcw;
        integer target;
        begin
            print_group_header("GROUP 10: JV (V flag + flush)");

            for (i=0;i<256;i=i+1) DUT.UNIFIED_MEM.mem[i]=8'h00;
            pcw=0;
            target=8'h38;

            // LDM R0,#7F
            DUT.UNIFIED_MEM.mem[pcw]=8'hC0; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw]=8'h7F; pcw=pcw+1;

            // LDM R1,#01
            DUT.UNIFIED_MEM.mem[pcw]=8'hC1; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw]=8'h01; pcw=pcw+1;

            // ADD R0,R1 => 0x80, signed overflow => V=1  (0x21)
            DUT.UNIFIED_MEM.mem[pcw]=8'h21; pcw=pcw+1;

            reset_cpu();
            run_cycles(40);
            check_flag_v(1, "V should be 1 after 0x7F + 0x01 overflow");

            // rebuild with branch
            for (i=0;i<256;i=i+1) DUT.UNIFIED_MEM.mem[i]=8'h00;
            pcw=0;

            DUT.UNIFIED_MEM.mem[pcw]=8'hC0; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw]=8'h7F; pcw=pcw+1;

            DUT.UNIFIED_MEM.mem[pcw]=8'hC1; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw]=8'h01; pcw=pcw+1;

            DUT.UNIFIED_MEM.mem[pcw]=8'h21; pcw=pcw+1;

            // LDM R2,#target
            DUT.UNIFIED_MEM.mem[pcw]=8'hC2; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw]=target[7:0]; pcw=pcw+1;

            // JV R2 : opcode 9, ra=11(V), rb=10(R2) => 0x9E
            DUT.UNIFIED_MEM.mem[pcw]=8'h9E; pcw=pcw+1;

            // flushed
            DUT.UNIFIED_MEM.mem[pcw]=8'hC3; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw]=8'h11; pcw=pcw+1;

            while (pcw < target) begin
                DUT.UNIFIED_MEM.mem[pcw]=8'h00; pcw=pcw+1;
            end

            // target: LDM R3,#AA
            DUT.UNIFIED_MEM.mem[pcw]=8'hC3; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw]=8'hAA; pcw=pcw+1;

            reset_cpu();
            run_cycles(500);

            check_reg(2'd3, 8'hAA, "JV taken -> R3=0xAA (flush 0x11)");

            print_group_footer();
        end
    endtask

    // ============================
    // GROUP 11: RTI (standalone stack-preload)
    // ============================
    task test_group_11_rti_standalone;
        integer i;
        integer pcw;
        reg [7:0] sp0;
        reg [7:0] ret_pc;
        reg [3:0] ccr_saved;
        begin
            print_group_header("GROUP 11: RTI (standalone stack-preload)");

            // --------- constants ----------
            sp0      = 8'hF0;      // initial SP
            ret_pc   = 8'h10;      // where we want RTI to return
            

            // --------- clear memory ----------
            for (i = 0; i < 256; i = i + 1)
                DUT.UNIFIED_MEM.mem[i] = 8'h00;

            // --------- preload stack frame ----------
            // Stack layout expected by your memory_stage RTI FSM:
            // [SP+1] -> return PC
            // [SP+2] -> CCR (low nibble)
            DUT.UNIFIED_MEM.mem[sp0 + 8'h01] = ret_pc;                 // PC
            DUT.UNIFIED_MEM.mem[sp0 + 8'h02] = {4'h0, ccr_saved};      // CCR in low nibble

            // --------- program at 0x00 ----------
            pcw = 0;

            // LDM R3,#sp0  (R3 is SP)
            DUT.UNIFIED_MEM.mem[pcw] = 8'hC3; pcw=pcw+1;
            DUT.UNIFIED_MEM.mem[pcw] = sp0;   pcw=pcw+1;

            // (optional) mess flags before RTI so we prove restoration really happens
            // SETC  (opcode 6 ra=10 => 0x68)
            DUT.UNIFIED_MEM.mem[pcw] = 8'h68; pcw=pcw+1;
            // CLRC  (opcode 6 ra=11 => 0x6C)
            DUT.UNIFIED_MEM.mem[pcw] = 8'h6C; pcw=pcw+1;

            // RTI: opcode B ra=11 rb=00 => 0xBC
            DUT.UNIFIED_MEM.mem[pcw] = 8'hBC; pcw=pcw+1;

            // filler
            DUT.UNIFIED_MEM.mem[pcw] = 8'h00; pcw=pcw+1;

            // --------- code at return PC (0x10) ----------
            // LDM R0,#0x22  at 0x10
            DUT.UNIFIED_MEM.mem[8'h10] = 8'hC0;
            DUT.UNIFIED_MEM.mem[8'h11] = 8'h22;

            // --------- run ----------
            reset_cpu();
            run_cycles(300);

            // --------- checks ----------
            check_reg(2'd0, 8'h22, "RTI returned to PC=0x10 and executed LDM R0,#0x22");
            run_cycles(2);
            check_reg(2'd3, (sp0 + 8'h02), "RTI updated SP by +2 (pop PC then pop CCR)");

            print_group_footer();
        end
    endtask




    // ============================
    // Helper Tasks (Fixed Paths)
    // ============================

    task wait_wb_to_reg;
        input [1:0] reg_idx;
        integer guard;
        begin
            guard = 0;
            while (!(DUT.RF.reg_write === 1'b1 && DUT.RF.rd_index === reg_idx)) begin
                @(posedge clk);
                guard = guard + 1;
                if (guard > 2000) begin
                    $display(" wait_wb_to_reg TIMEOUT: waiting WB to R%0d (PC=%02h instr=%02h)",
                             reg_idx, {1'b0, DUT.FETCH.pc}, DUT.FETCH.instruction);

                    $finish;
                end
            end
            #1; // allow data settle
        end
    endtask

    task reset_cpu;
        begin
            reset_in = 1;
            #20;
            reset_in = 0;
            run_cycles(6);
        end
    endtask

    task run_cycles;
        input integer n;
        begin
            repeat(n) @(posedge clk);
            #1;
        end
    endtask

    task wait_pc;
        input [7:0] target;
        integer guard;
        begin
            guard = 0;
            // Path: FETCH_STG.pc
            while (DUT.FETCH.pc !== target[6:0]) begin
                @(posedge clk);
                guard = guard + 1;
                if (guard > 2000) begin
                    $display(" wait_pc TIMEOUT: target PC=0x%02h, current PC=0x%02h",
                             target, {1'b0, DUT.FETCH.pc});
                    $finish;
                end
            end
            #1;
        end
    endtask

    task check_reg;
        input [1:0] reg_idx;
        input [7:0] expected;
        input [200*8:1] desc;
        reg [7:0] actual;
        begin
            test_count = test_count + 1;
            // Path: DECODE_STG.u_regfile.regs
           actual = DUT.RF.regs[reg_idx];

            if (actual == expected) begin
                $display("  ✓ Test %0d PASS: %0s (R%0d=0x%02h)",
                         test_count, desc, reg_idx, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  ✗ Test %0d FAIL: %0s (R%0d=0x%02h, expected 0x%02h)",
                         test_count, desc, reg_idx, actual, expected);
                $display("      PC=0x%02h", {1'b0, DUT.FETCH.pc});
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_flag_c;
        input expected;
        input [200*8:1] desc;
        reg actual;
        begin
            test_count = test_count + 1;
            // Path: EXECUTE_STG.CCR.ccr_out
           actual = DUT.EX.CCR.ccr_out[2]; // [2]=C

            if (actual == expected) begin
                $display("  ✓ Test %0d PASS: %0s (C=%0b)", test_count, desc, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  ✗ Test %0d FAIL: %0s (C=%0b, expected %0b)",
                         test_count, desc, actual, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_flag_z;
        input expected;
        input [200*8:1] desc;
        reg actual;
        begin
            test_count = test_count + 1;
            actual = DUT.EX.CCR.ccr_out[0]; // Z

            if (actual == expected) begin
                $display("  ✓ Test %0d PASS: %0s (Z=%0b)", test_count, desc, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  ✗ Test %0d FAIL: %0s (Z=%0b, expected %0b)", test_count, desc, actual, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_flag_n;
        input expected;
        input [200*8:1] desc;
        reg actual;
        begin
            test_count = test_count + 1;
            actual = DUT.EX.CCR.ccr_out[1]; // N

            if (actual == expected) begin
                $display("  ✓ Test %0d PASS: %0s (N=%0b)", test_count, desc, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  ✗ Test %0d FAIL: %0s (N=%0b, expected %0b)", test_count, desc, actual, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_flag_v;
        input expected;
        input [200*8:1] desc;
        reg actual;
        begin
            test_count = test_count + 1;
            actual = DUT.EX.CCR.ccr_out[3]; // V

            if (actual == expected) begin
                $display("  ✓ Test %0d PASS: %0s (V=%0b)", test_count, desc, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  ✗ Test %0d FAIL: %0s (V=%0b, expected %0b)", test_count, desc, actual, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_ccr;
        input [3:0] expected;
        input [200*8:1] desc;
        reg [3:0] actual;
        begin
            test_count = test_count + 1;
            actual = DUT.EX.CCR.ccr_out; // [3]=V [2]=C [1]=N [0]=Z

            if (actual === expected) begin
                $display("  ✓ Test %0d PASS: %0s (CCR=%b)", test_count, desc, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  ✗ Test %0d FAIL: %0s (CCR=%b expected %b)", test_count, desc, actual, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask



    // ============================
    // Memory Initializations (No Gaps)
    // ============================
    task init_memory_group1;
        integer i;
        begin
            $display("  📝 Initializing Group 1 (Sequential)...");
            for (i = 0; i < 256; i = i + 1)   DUT.UNIFIED_MEM.mem[i] = 8'h00;

            DUT.UNIFIED_MEM.mem[8'h00] = 8'hC0; DUT.UNIFIED_MEM.mem[8'h01] = 8'h05; // LDM R0,#5
            DUT.UNIFIED_MEM.mem[8'h02] = 8'h14; // MOV R1,R0
            DUT.UNIFIED_MEM.mem[8'h03] = 8'h21; // ADD R0,R1
            DUT.UNIFIED_MEM.mem[8'h04] = 8'h31; // SUB R0,R1
            DUT.UNIFIED_MEM.mem[8'h05] = 8'hC2; DUT.UNIFIED_MEM.mem[8'h06] = 8'h0F; // LDM R2,#15
            DUT.UNIFIED_MEM.mem[8'h07] = 8'h49; // AND R2,R1
            DUT.UNIFIED_MEM.mem[8'h08] = 8'hC2; DUT.UNIFIED_MEM.mem[8'h09] = 8'h0A; // LDM R2,#10
            DUT.UNIFIED_MEM.mem[8'h0A] = 8'h59; // OR R2,R1
            DUT.UNIFIED_MEM.mem[8'h0B] = 8'h80; // NOT R0
            DUT.UNIFIED_MEM.mem[8'h0C] = 8'h85; // NEG R1
        end
    endtask

    task init_memory_group2;
        integer i;
        begin
            $display("  📝 Initializing Group 2 (Sequential)...");
            for (i = 0; i < 256; i = i + 1) DUT.UNIFIED_MEM.mem[i] = 8'h00;

            DUT.UNIFIED_MEM.mem[8'h00] = 8'hC0; DUT.UNIFIED_MEM.mem[8'h01] = 8'h05; // LDM R0,#5
            DUT.UNIFIED_MEM.mem[8'h02] = 8'h88; // INC R0
            DUT.UNIFIED_MEM.mem[8'h03] = 8'h8C; // DEC R0
            DUT.UNIFIED_MEM.mem[8'h04] = 8'h68; // SETC
            DUT.UNIFIED_MEM.mem[8'h05] = 8'hC1; DUT.UNIFIED_MEM.mem[8'h06] = 8'h05; // LDM R1,#5
            DUT.UNIFIED_MEM.mem[8'h07] = 8'h61; // RLC R1
            DUT.UNIFIED_MEM.mem[8'h08] = 8'h6C; // CLRC
            DUT.UNIFIED_MEM.mem[8'h09] = 8'h65; // RRC R1
        end
    endtask

    task print_group_header;
        input [500*8:1] title;
        begin
            $display("\n========================================");
            $display("  %0s", title);
            $display("========================================");
        end
    endtask

    task print_group_footer;
        begin
            $display("----------------------------------------\n");
        end
    endtask

    task print_final_report;
        begin
            $display("\n========================================");
            $display("  FINAL TEST REPORT");
            $display("========================================");
            $display("  Total Tests:  %0d", test_count);
            $display("  Passed:       %0d", pass_count);
            $display("  Failed:       %0d", fail_count);
            if (test_count > 0)
                $display("  Pass Rate:    %0d%%", (pass_count * 100) / test_count);
            $display("========================================\n");
        end
    endtask

    initial begin
        $dumpfile("cpu_test.vcd");
        $dumpvars(0, tb_cpu_modular);
    end

    initial begin
        #100000;
        $display("\n TIMEOUT!");
        print_final_report();
        $finish;
    end

endmodule