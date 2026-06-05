# 建立 Phase10 PS/PL DMA integration project，目標板為 PYNQ-Z2。
#
# 這份 Tcl 只針對：
#   model_lite/sr_core/vivado/sr_core_phase10_ps_dma_pynqz2
#
# 不可以 open、modify 或 regenerate：
#   model_lite/sr_core/vivado/sr_core_clean_stream_pynqz2
#
# Phase10 wrapper RTL 尚未實作。block design 會保留清楚的
# sr_core_ps_dma_wrapper 插入點。

set script_dir  [file dirname [file normalize [info script]]]
set project_dir [file normalize [file join $script_dir ..]]
set project_name sr_core_phase10_ps_dma_pynqz2
set bd_name sr_core_phase10_bd

set part_name xc7z020clg400-1
set board_part tul.com.tw:pynq-z2:part0:1.0

set xpr_path [file join $project_dir ${project_name}.xpr]

if {[file exists $xpr_path]} {
    open_project $xpr_path
} else {
    create_project $project_name $project_dir -part $part_name
    set_property board_part $board_part [current_project]
}

set_property target_language Verilog [current_project]
set_property simulator_language Verilog [current_project]

if {[llength [get_files -quiet ${bd_name}.bd]] == 0} {
    create_bd_design $bd_name
} else {
    open_bd_design [get_files ${bd_name}.bd]
}

# ---------------------------------------------------------------------------
# Phase10 新增 IP
# ---------------------------------------------------------------------------
# processing_system7_0：
#   提供 PS host、DDR、FCLK、AXI GP master，以及 DMA 存取 DDR 用的 HP slave。
if {[llength [get_bd_cells -quiet processing_system7_0]] == 0} {
    create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
    apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
        -config {make_external "FIXED_IO, DDR" apply_board_preset "1"} \
        [get_bd_cells processing_system7_0]
}

# axi_dma_0：
#   MM2S 把 128x128 uint8 input 從 PS DDR 搬到 wrapper S_AXIS。
#   S2MM 把 256x256 uint8 output 從 wrapper M_AXIS 搬回 PS DDR。
if {[llength [get_bd_cells -quiet axi_dma_0]] == 0} {
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0
    set_property -dict [list \
        CONFIG.c_include_sg {0} \
        CONFIG.c_sg_include_stscntrl_strm {0} \
        CONFIG.c_include_mm2s {1} \
        CONFIG.c_include_s2mm {1} \
        CONFIG.c_m_axi_mm2s_data_width {32} \
        CONFIG.c_m_axi_s2mm_data_width {32} \
        CONFIG.c_m_axis_mm2s_tdata_width {32} \
        CONFIG.c_s_axis_s2mm_tdata_width {32} \
    ] [get_bd_cells axi_dma_0]
}

# axi_interconnect_0：
#   把 PS M_AXI_GP0 的 AXI-Lite transaction 分到 DMA registers
#   和未來 wrapper control/status registers。
if {[llength [get_bd_cells -quiet axi_interconnect_0]] == 0} {
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
    set_property -dict [list CONFIG.NUM_MI {2}] [get_bd_cells axi_interconnect_0]
}

# proc_sys_reset_0：
#   把 PS FCLK reset 轉成 peripheral reset nets。
if {[llength [get_bd_cells -quiet proc_sys_reset_0]] == 0} {
    create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
}

# ---------------------------------------------------------------------------
# 基本 clock/reset 拉線。
# ---------------------------------------------------------------------------
connect_bd_net -quiet [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_dma_0/s_axi_lite_aclk]
connect_bd_net -quiet [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_dma_0/m_axi_mm2s_aclk]
connect_bd_net -quiet [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_dma_0/m_axi_s2mm_aclk]
connect_bd_net -quiet [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net -quiet [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net -quiet [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_interconnect_0/M00_ACLK]
connect_bd_net -quiet [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_interconnect_0/M01_ACLK]
connect_bd_net -quiet [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]

connect_bd_net -quiet [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins proc_sys_reset_0/ext_reset_in]
connect_bd_net -quiet [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_dma_0/axi_resetn]
connect_bd_net -quiet [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net -quiet [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net -quiet [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M00_ARESETN]
connect_bd_net -quiet [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M01_ARESETN]

# ---------------------------------------------------------------------------
# AXI-Lite 和 DMA DDR access。
# ---------------------------------------------------------------------------
connect_bd_intf_net -quiet [get_bd_intf_pins processing_system7_0/M_AXI_GP0] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_intf_net -quiet [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins axi_dma_0/S_AXI_LITE]

# 若 board preset 尚未啟用 PS HP0，這裡補上 DMA DDR access 設定。
set_property -dict [list CONFIG.PCW_USE_S_AXI_HP0 {1}] [get_bd_cells processing_system7_0]
connect_bd_intf_net -quiet [get_bd_intf_pins axi_dma_0/M_AXI_MM2S] [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
connect_bd_intf_net -quiet [get_bd_intf_pins axi_dma_0/M_AXI_S2MM] [get_bd_intf_pins processing_system7_0/S_AXI_HP0]

# ---------------------------------------------------------------------------
# 未來 wrapper 插入點。
# ---------------------------------------------------------------------------
# 等 sr_core_ps_dma_wrapper.v 完成後，把它加成 module reference，並依下列方式拉線：
#
# Clock/reset：
#   processing_system7_0/FCLK_CLK0
#       -> sr_core_ps_dma_wrapper/aclk
#   proc_sys_reset_0/peripheral_aresetn
#       -> sr_core_ps_dma_wrapper/aresetn
#
# AXI-Lite：
#   axi_interconnect_0/M01_AXI
#       -> sr_core_ps_dma_wrapper/S_AXI
#
# AXI Stream：
#   axi_dma_0/M_AXIS_MM2S
#       -> sr_core_ps_dma_wrapper/S_AXIS
#   sr_core_ps_dma_wrapper/M_AXIS
#       -> axi_dma_0/S_AXIS_S2MM
#
# v1 使用 PS polling，暫時不要接 DMA interrupts。

# Vivado 專案驗證要放在流程最後。這份 scaffold 只在 PS、DMA、reset、
# interconnect 和 address map 準備好後才 validate。
assign_bd_address
validate_bd_design
save_bd_design
save_project_as $project_name $project_dir -force

puts "Phase10 PS DMA Vivado project scaffold 已建立於：$project_dir"
