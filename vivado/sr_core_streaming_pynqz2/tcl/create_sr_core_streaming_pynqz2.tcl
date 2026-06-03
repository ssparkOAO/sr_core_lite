# -----------------------------------------------------------------------------
# create_sr_core_streaming_pynqz2.tcl
# -----------------------------------------------------------------------------
# Phase9 streaming architecture Vivado project.
#
# This project is separate from:
#   vivado/sr_core_bram_pynqz2
#
# Purpose:
#   - keep the Phase8 parameter ROM IP architecture
#   - add Phase9 feature/output RAM IP prototypes
#   - prepare for reference-like CNN datapath + memory IP same-level hierarchy
# -----------------------------------------------------------------------------

set script_dir [file dirname [file normalize [info script]]]
set project_dir [file normalize [file join $script_dir ..]]
set sr_core_dir [file normalize [file join $project_dir .. ..]]
set repo_root   [file normalize [file join $sr_core_dir .. ..]]

set project_name sr_core_streaming_pynqz2
set part_name xc7z020clg400-1
set board_part tul.com.tw:pynq-z2:part0:1.0

create_project $project_name $project_dir -part $part_name -force
set_property board_part $board_part [current_project]
set_property target_language Verilog [current_project]
set_property simulator_language Verilog [current_project]

# -----------------------------------------------------------------------------
# Source files
# -----------------------------------------------------------------------------
add_files -norecurse [file join $sr_core_dir RTL_sys phase9_3_ref_hier rtl sr_pctrl.v]
add_files -norecurse [file join $sr_core_dir RTL_sys phase9_3_ref_hier rtl sr_ctrl.v]
add_files -norecurse [file join $sr_core_dir RTL_sys phase9_3_ref_hier rtl sr_c1c3_slice.v]
add_files -norecurse [file join $sr_core_dir RTL_sys phase9_3_ref_hier rtl sr_out_pack.v]
add_files -norecurse [file join $sr_core_dir RTL_sys phase9_3_ref_hier rtl sr_nn_top.v]

add_files -norecurse [file join $sr_core_dir RTL sr_requantize sr_requantize.v]
add_files -norecurse [file join $sr_core_dir RTL sr_conv3x3_cin1_cout8_mac sr_window_3x3_cin1.v]
add_files -norecurse [file join $sr_core_dir RTL sr_conv3x3_cin1_cout8_mac sr_conv3x3_cin1_cout8_mac.v]
add_files -norecurse [file join $sr_core_dir RTL sr_conv1_3x3_cin1_cout8_block sr_conv1_3x3_cin1_cout8_block.v]
add_files -norecurse [file join $sr_core_dir RTL sr_conv1x1_cin8_cout4_mac sr_conv1x1_cin8_cout4_mac.v]
add_files -norecurse [file join $sr_core_dir RTL sr_conv1x1_cin8_cout4_block sr_conv1x1_cin8_cout4_block.v]
add_files -norecurse [file join $sr_core_dir RTL sr_pixel_shuffle_x2 pixel_shuffle_core.v]
add_files -norecurse [file join $sr_core_dir RTL sr_output_stage sr_output_stage.v]

add_files -fileset sim_1 -norecurse [file join $sr_core_dir RTL_sys phase9_4_ip_verify sim tb_sr_nn_top_ip.v]

# -----------------------------------------------------------------------------
# Parameter ROM IP
# -----------------------------------------------------------------------------
proc create_single_port_rom {ip_name width depth coe_file} {
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
    generate_target all [get_ips $ip_name]
}

set hex_dir [file normalize [file join $sr_core_dir generated_vivado_hex]]

create_single_port_rom conv1_weight_rom 8  72 [file join $hex_dir conv1_weight.coe]
create_single_port_rom conv3_weight_rom 8  32 [file join $hex_dir conv3_weight.coe]
create_single_port_rom conv1_m0_rom     32 8  [file join $hex_dir conv1_m0.coe]
create_single_port_rom conv1_m1_rom     64 8  [file join $hex_dir conv1_m1.coe]
create_single_port_rom conv3_m0_rom     32 4  [file join $hex_dir conv3_m0.coe]
create_single_port_rom conv3_m1_rom     64 4  [file join $hex_dir conv3_m1.coe]

# -----------------------------------------------------------------------------
# Phase9 feature/output RAM IP
# -----------------------------------------------------------------------------
# conv3_feature_ram:
#   One 32-bit word per LR pixel:
#     {c3, c2, c1, c0}
#   depth = 8 * 8 = 64
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name conv3_feature_ram
set_property -dict [list \
    CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
    CONFIG.Write_Width_A {32} \
    CONFIG.Read_Width_A {32} \
    CONFIG.Write_Depth_A {64} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Enable_B {Use_ENB_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortB_Output_of_Memory_Core {false} \
] [get_ips conv3_feature_ram]
generate_target all [get_ips conv3_feature_ram]

# output_image_ram:
#   One 16-bit word stores two adjacent uint8 HR pixels:
#     {right_pixel, left_pixel}
#   depth = 16 * 16 / 2 = 128
#   True dual-port RAM allows even-row and odd-row PixelShuffle writes in
#   the same clock cycle.
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name output_image_ram
set_property -dict [list \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Width_B {16} \
    CONFIG.Read_Width_B {16} \
    CONFIG.Write_Depth_A {128} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Enable_B {Use_ENB_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortB_Output_of_Memory_Core {false} \
] [get_ips output_image_ram]
generate_target all [get_ips output_image_ram]

set_property top sr_nn_top [get_filesets sources_1]
set_property top tb_sr_nn_top_ip [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Created $project_name at $project_dir"
