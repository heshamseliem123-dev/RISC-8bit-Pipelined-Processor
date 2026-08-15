onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_cpu_modular/clk
add wave -noupdate /tb_cpu_modular/reset_in
add wave -noupdate /tb_cpu_modular/intr_in
add wave -noupdate /tb_cpu_modular/IN_PORT
add wave -noupdate /tb_cpu_modular/OUT_PORT
add wave -noupdate /tb_cpu_modular/test_count
add wave -noupdate /tb_cpu_modular/pass_count
add wave -noupdate /tb_cpu_modular/fail_count
add wave -noupdate -label instruction /tb_cpu_modular/DUT/FETCH/instruction
add wave -noupdate /tb_cpu_modular/DUT/FETCH/pc
add wave -noupdate /tb_cpu_modular/DUT/FETCH/next_byte
add wave -noupdate /tb_cpu_modular/DUT/DECODE/cu_rd_index
add wave -noupdate /tb_cpu_modular/DUT/DECODE/cu_reg_write
add wave -noupdate /tb_cpu_modular/DUT/DECODE/id_ex_imm_or_ea
add wave -noupdate /tb_cpu_modular/DUT/EX/alu/b
add wave -noupdate /tb_cpu_modular/DUT/EX/alu/alu_op
add wave -noupdate /tb_cpu_modular/DUT/EX/alu/result
add wave -noupdate /tb_cpu_modular/DUT/MEM/mem_wb_data
add wave -noupdate /tb_cpu_modular/DUT/MEM/ex_mem_reg_write
add wave -noupdate /tb_cpu_modular/DUT/RF/reg_write
add wave -noupdate /tb_cpu_modular/DUT/RF/rd_index
add wave -noupdate /tb_cpu_modular/DUT/RF/rd_data
add wave -noupdate /tb_cpu_modular/DUT/HU/pc_write
add wave -noupdate /tb_cpu_modular/DUT/HU/if_id_write
add wave -noupdate /tb_cpu_modular/DUT/FETCH/rd_a
add wave -noupdate /tb_cpu_modular/DUT/FWD_U/fwd_A
add wave -noupdate /tb_cpu_modular/DUT/FWD_U/fwd_B
add wave -noupdate {/tb_cpu_modular/DUT/RF/regs[0]}
add wave -noupdate {/tb_cpu_modular/DUT/RF/regs[1]}
add wave -noupdate {/tb_cpu_modular/DUT/RF/regs[2]}
add wave -noupdate {/tb_cpu_modular/DUT/RF/regs[3]}
add wave -noupdate {/tb_cpu_modular/DUT/EX/CCR/ccr_out[0]}
add wave -noupdate {/tb_cpu_modular/DUT/EX/CCR/ccr_out[1]}
add wave -noupdate {/tb_cpu_modular/DUT/EX/CCR/ccr_out[2]}
add wave -noupdate {/tb_cpu_modular/DUT/EX/CCR/ccr_out[3]}
add wave -noupdate {/tb_cpu_modular/DUT/UNIFIED_MEM/mem[255]}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {23645826 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 315
configure wave -valuecolwidth 185
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {23596673 ps} {23905991 ps}
