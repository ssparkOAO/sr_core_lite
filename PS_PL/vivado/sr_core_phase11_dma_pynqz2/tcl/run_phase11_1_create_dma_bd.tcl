# Phase11.1 SR Accelerator IP Packaging + AXI DMA Block Design
# Run with:
#   vivado.bat -mode batch -source PS_PL/vivado/sr_core_phase11_dma_pynqz2/tcl/run_phase11_1_create_dma_bd.tcl

set script_dir [file normalize [file dirname [info script]]]
set project_dir [file normalize [file join $script_dir ..]]
set pspl_dir    [file normalize [file join $project_dir .. ..]]
set sr_core_dir [file normalize [file join $pspl_dir ..]]

set project_name "sr_core_phase11_dma_pynqz2"
set part_name "xc7z020clg400-1"
set bd_name "sr_core_dma_bd"

set result_dir [file normalize [file join $pspl_dir RTL phase11_1_dma_block_design result]]
file mkdir $result_dir
set result_file [file normalize [file join $result_dir phase11_1_dma_block_design_result.txt]]
set fp [open $result_file w]
puts $fp "Phase11.1 SR Accelerator IP Packaging + AXI DMA Block Design"
puts $fp "Project: $project_dir"
puts $fp "Result file: $result_file"
puts $fp ""

proc log_line {fp msg} {
    puts $msg
    puts $fp $msg
    flush $fp
}

log_line $fp "Creating Vivado project..."
create_project $project_name $project_dir -part $part_name -force
set_property target_language Verilog [current_project]
set_property simulator_language Verilog [current_project]

if {[catch {set_property board_part tul.com.tw:pynq-z2:part0:1.0 [current_project]} board_err]} {
    log_line $fp "Board part was not set automatically: $board_err"
} else {
    log_line $fp "Board part set to PYNQ-Z2."
}

set shell_rtl [file normalize [file join $pspl_dir RTL phase11_1_dma_block_design rtl sr_accel_axis_ip_top.v]]
set wrapper_rtl [file normalize [file join $pspl_dir RTL phase10_ps_dma_wrapper rtl sr_core_axis_wrapper.v]]
set clean_src_dir [file normalize [file join $pspl_dir vivado sr_core_clean_stream_pynqz2 src rtl]]
set clean_ip_dir [file normalize [file join $pspl_dir vivado sr_core_clean_stream_pynqz2 sr_core_clean_stream_pynqz2.srcs sources_1 ip]]

set rtl_files [list \
    $shell_rtl \
    $wrapper_rtl \
    [file join $clean_src_dir sr_top_clean_stream_img.v] \
    [file join $clean_src_dir sr_ctrl_clean_stream_img.v] \
    [file join $clean_src_dir sr_conv1_3x3_cin1_cout8_flat.v] \
    [file join $clean_src_dir sr_conv1x1_cin8_cout4_flat.v] \
    [file join $clean_src_dir sr_conv1_to_conv3_stream_slice.v] \
    [file join $clean_src_dir sr_output_pack2x2_uint8.v] \
    [file join $clean_src_dir sr_pctrl.v] \
    [file join $clean_src_dir sr_requantize.v] \
    [file join $clean_src_dir sr_window_3x3_cin1.v] \
    [file join $clean_src_dir sr_conv3x3_cin1_cout8_mac.v] \
    [file join $clean_src_dir sr_conv1x1_cin8_cout4_mac.v] \
    [file join $clean_src_dir pixel_shuffle_core.v] \
    [file join $clean_src_dir sr_output_stage.v] \
]

foreach f $rtl_files {
    if {![file exists $f]} {
        log_line $fp "ERROR: missing RTL source: $f"
        close $fp
        error "Missing RTL source $f"
    }
}

log_line $fp "Adding RTL sources..."
add_files -norecurse $rtl_files
set_property top sr_accel_axis_ip_top [current_fileset]

proc create_bmg_rom {fp ip_name width depth coe_file} {
    log_line $fp "Creating ROM IP $ip_name from $coe_file"
    if {![file exists $coe_file]} {
        log_line $fp "ERROR: missing COE file for $ip_name: $coe_file"
        close $fp
        error "Missing COE file $coe_file"
    }
    create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name $ip_name
    set_property -dict [list \
        CONFIG.Memory_Type {Single_Port_ROM} \
        CONFIG.Write_Width_A $width \
        CONFIG.Read_Width_A $width \
        CONFIG.Write_Depth_A $depth \
        CONFIG.Enable_A {Use_ENA_Pin} \
        CONFIG.Load_Init_File {true} \
        CONFIG.Coe_File $coe_file \
        CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
        CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    ] [get_ips $ip_name]
}

proc create_output_image_ram {fp ip_name} {
    log_line $fp "Creating output RAM IP $ip_name"
    create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name $ip_name
    set_property -dict [list \
        CONFIG.Memory_Type {True_Dual_Port_RAM} \
        CONFIG.Write_Width_A {16} \
        CONFIG.Read_Width_A {16} \
        CONFIG.Write_Depth_A {32768} \
        CONFIG.Write_Width_B {16} \
        CONFIG.Read_Width_B {16} \
        CONFIG.Enable_A {Use_ENA_Pin} \
        CONFIG.Enable_B {Use_ENB_Pin} \
        CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
        CONFIG.Register_PortA_Output_of_Memory_Core {false} \
        CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
        CONFIG.Register_PortB_Output_of_Memory_Core {false} \
        CONFIG.Load_Init_File {false} \
    ] [get_ips $ip_name]
}

set coe_dir [file normalize [file join $sr_core_dir generated_vivado_hex]]
log_line $fp "Creating fresh BMG IPs in the Phase11.1 project..."
create_bmg_rom $fp conv1_weight_rom 8 72 [file join $coe_dir conv1_weight.coe]
create_bmg_rom $fp conv3_weight_rom 8 32 [file join $coe_dir conv3_weight.coe]
create_bmg_rom $fp conv1_m0_rom 32 8 [file join $coe_dir conv1_m0.coe]
create_bmg_rom $fp conv1_m1_rom 64 8 [file join $coe_dir conv1_m1.coe]
create_bmg_rom $fp conv3_m0_rom 32 4 [file join $coe_dir conv3_m0.coe]
create_bmg_rom $fp conv3_m1_rom 64 4 [file join $coe_dir conv3_m1.coe]
create_output_image_ram $fp output_image_ram
generate_target all [get_ips]

log_line $fp "Packaging SR accelerator AXIS IP..."
set ip_repo_dir [file normalize [file join $pspl_dir vivado ip_repo]]
set ip_root [file normalize [file join $ip_repo_dir sr_accel_axis_ip]]
file delete -force $ip_root
file mkdir $ip_root

ipx::package_project -root_dir $ip_root -vendor user.org -library user -taxonomy /UserIP -import_files -set_current true
set core [ipx::current_core]
set_property name sr_accel_axis_ip $core
set_property display_name {SR Accelerator AXI Stream IP} $core
set_property description {AXI4-Stream shell around the frozen Phase9.6 clean-stream SR accelerator core.} $core
set_property version 1.0 $core
set_property supported_families {zynq Production} $core

if {[catch {ipx::infer_bus_interface s_axis xilinx.com:interface:axis_rtl:1.0 $core} infer_s_err]} {
    log_line $fp "S_AXIS infer warning: $infer_s_err"
}
if {[catch {ipx::infer_bus_interface m_axis xilinx.com:interface:axis_rtl:1.0 $core} infer_m_err]} {
    log_line $fp "M_AXIS infer warning: $infer_m_err"
}
if {[catch {ipx::associate_bus_interfaces -busif s_axis -clock aclk $core} assoc_s_err]} {
    log_line $fp "S_AXIS clock association warning: $assoc_s_err"
}
if {[catch {ipx::associate_bus_interfaces -busif m_axis -clock aclk $core} assoc_m_err]} {
    log_line $fp "M_AXIS clock association warning: $assoc_m_err"
}
if {[catch {ipx::associate_bus_interfaces -clock aclk -reset aresetn $core} assoc_rst_err]} {
    log_line $fp "Reset association warning: $assoc_rst_err"
}

ipx::update_checksums $core
ipx::save_core $core
ipx::unload_core $core

set_property ip_repo_paths $ip_repo_dir [current_project]
update_ip_catalog

log_line $fp "Creating block design..."
create_bd_design $bd_name

create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 zynq_ps
if {[catch {apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1"} [get_bd_cells zynq_ps]} ps_auto_err]} {
    log_line $fp "PS automation warning: $ps_auto_err"
}
set_property -dict [list CONFIG.PCW_USE_S_AXI_HP0 {1} CONFIG.PCW_USE_M_AXI_GP0 {1}] [get_bd_cells zynq_ps]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0
set_property -dict [list \
    CONFIG.c_include_sg {0} \
    CONFIG.c_include_mm2s {1} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_m_axis_mm2s_tdata_width {8} \
    CONFIG.c_s_axis_s2mm_tdata_width {8} \
] [get_bd_cells axi_dma_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_100M
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_mem
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {1}] [get_bd_cells smartconnect_mem]
create_bd_cell -type ip -vlnv user.org:user:sr_accel_axis_ip:1.0 sr_accel_axis_0

log_line $fp "Connecting clocks and resets..."
connect_bd_net [get_bd_pins zynq_ps/FCLK_CLK0] [get_bd_pins axi_dma_0/s_axi_lite_aclk]
connect_bd_net [get_bd_pins zynq_ps/FCLK_CLK0] [get_bd_pins axi_dma_0/m_axi_mm2s_aclk]
connect_bd_net [get_bd_pins zynq_ps/FCLK_CLK0] [get_bd_pins axi_dma_0/m_axi_s2mm_aclk]
connect_bd_net [get_bd_pins zynq_ps/FCLK_CLK0] [get_bd_pins zynq_ps/S_AXI_HP0_ACLK]
connect_bd_net [get_bd_pins zynq_ps/FCLK_CLK0] [get_bd_pins rst_ps7_0_100M/slowest_sync_clk]
connect_bd_net [get_bd_pins zynq_ps/FCLK_CLK0] [get_bd_pins sr_accel_axis_0/aclk]
connect_bd_net [get_bd_pins zynq_ps/FCLK_CLK0] [get_bd_pins smartconnect_mem/aclk]
connect_bd_net [get_bd_pins zynq_ps/FCLK_RESET0_N] [get_bd_pins rst_ps7_0_100M/ext_reset_in]
connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins axi_dma_0/axi_resetn]
connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins sr_accel_axis_0/aresetn]
connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins smartconnect_mem/aresetn]

log_line $fp "Connecting AXI streams..."
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXIS_MM2S] [get_bd_intf_pins sr_accel_axis_0/s_axis]
connect_bd_intf_net [get_bd_intf_pins sr_accel_axis_0/m_axis] [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM]

log_line $fp "Running connection automation for AXI memory-mapped ports..."
if {[catch {apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/zynq_ps/M_AXI_GP0" Clk_master "/zynq_ps/FCLK_CLK0" Clk_slave "/zynq_ps/FCLK_CLK0" Clk_xbar "/zynq_ps/FCLK_CLK0"} [get_bd_intf_pins axi_dma_0/S_AXI_LITE]} auto_lite_err]} {
    log_line $fp "AXI-Lite automation warning: $auto_lite_err"
}

log_line $fp "Connecting DMA memory-mapped data ports to PS HP0 through SmartConnect..."
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXI_MM2S] [get_bd_intf_pins smartconnect_mem/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXI_S2MM] [get_bd_intf_pins smartconnect_mem/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins smartconnect_mem/M00_AXI] [get_bd_intf_pins zynq_ps/S_AXI_HP0]

log_line $fp "Assigning addresses..."
assign_bd_address

log_line $fp "Validating block design..."
if {[catch {validate_bd_design} validate_err]} {
    log_line $fp "VALIDATE_FAIL: $validate_err"
    save_bd_design
    close $fp
    error $validate_err
} else {
    log_line $fp "VALIDATE_PASS"
}

save_bd_design

log_line $fp "Creating HDL wrapper..."
make_wrapper -files [get_files [file join $project_dir ${project_name}.srcs sources_1 bd $bd_name ${bd_name}.bd]] -top
add_files -norecurse [file join $project_dir ${project_name}.gen sources_1 bd $bd_name hdl ${bd_name}_wrapper.v]
set_property top ${bd_name}_wrapper [current_fileset]

log_line $fp "Launching synthesis..."
launch_runs synth_1 -jobs 2
wait_on_run synth_1
set synth_status [get_property STATUS [get_runs synth_1]]
log_line $fp "SYNTH_STATUS: $synth_status"
if {[string first "synth_design Complete" $synth_status] >= 0 || [string first "Complete" $synth_status] >= 0} {
    log_line $fp "SYNTH_PASS"
} else {
    log_line $fp "SYNTH_FAIL"
    close $fp
    error "Synthesis did not complete successfully: $synth_status"
}

log_line $fp ""
log_line $fp "Phase11.1 result: PASS"
close $fp
exit
