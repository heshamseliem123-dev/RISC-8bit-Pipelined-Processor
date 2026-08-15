
vlib work

vlog -work work "D:/first term/Labs/my processor/alu.v"
vlog -work work "D:/first term/Labs/my processor/branch_unit.v"
vlog -work work "D:/first term/Labs/my processor/ccr_reg.v"
vlog -work work "D:/first term/Labs/my processor/control_unit.v"
vlog -work work "D:/first term/Labs/my processor/cpu_tb.v"
vlog -work work "D:/first term/Labs/my processor/cpu_tob.v"
vlog -work work "D:/first term/Labs/my processor/decode_stage.v"
vlog -work work "D:/first term/Labs/my processor/ex_mem_reg.v"
vlog -work work "D:/first term/Labs/my processor/ex_stage.v"
vlog -work work "D:/first term/Labs/my processor/fetch_stage.v"
vlog -work work "D:/first term/Labs/my processor/forwarding_unit.v"
vlog -work work "D:/first term/Labs/my processor/hazard_unit.v"
vlog -work work "D:/first term/Labs/my processor/interrupt_controller.v"
vlog -work work "D:/first term/Labs/my processor/io_controller.v"
vlog -work work "D:/first term/Labs/my processor/mem_addr_mux.v"
vlog -work work "D:/first term/Labs/my processor/mem_dualport.v"
vlog -work work "D:/first term/Labs/my processor/mem_wb_reg.v"
vlog -work work "D:/first term/Labs/my processor/memory_stage.v"
vlog -work work "D:/first term/Labs/my processor/mux4to1_8bit.v"
vlog -work work "D:/first term/Labs/my processor/mux5to1.v"
vlog -work work "D:/first term/Labs/my processor/pc.v"
vlog -work work "D:/first term/Labs/my processor/reg_file.v"
vlog -work work "D:/first term/Labs/my processor/sp_update.v"
vlog -work work "D:/first term/Labs/my processor/wb_mux.v"

vsim -voptargs=+acc work.tb_cpu_modular

do wave.do
run -all
#quit -sim