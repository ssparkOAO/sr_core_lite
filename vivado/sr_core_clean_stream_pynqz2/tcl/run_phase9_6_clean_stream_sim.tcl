# Run Phase9.6 clean streaming image-level SR simulation with Vivado BMG IP.

set script_dir  [file dirname [file normalize [info script]]]
set project_dir [file normalize [file join $script_dir ..]]
set sr_core_dir [file normalize [file join $project_dir .. ..]]

set project_name sr_core_clean_stream_pynqz2
set xpr_path [file join $project_dir ${project_name}.xpr]
set part_name xc7z020clg400-1
set board_part tul.com.tw:pynq-z2:part0:1.0

if {[file exists $xpr_path]} {
    open_project $xpr_path
} else {
    create_project $project_name $project_dir -part $part_name
    set_property board_part $board_part [current_project]
}

set_property target_language Verilog [current_project]
set_property simulator_language Verilog [current_project]

proc add_source_if_missing {path} {
    if {[llength [get_files -quiet $path]] == 0} {
        add_files -norecurse $path
    }
}

proc add_sim_if_missing {path} {
    if {[llength [get_files -quiet $path]] == 0} {
        add_files -fileset sim_1 -norecurse $path
    }
}

proc create_single_port_rom_if_missing {ip_name width depth coe_file} {
    if {[llength [get_ips -quiet $ip_name]] == 0} {
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
}

proc create_true_dp_ram_if_missing {ip_name width depth} {
    if {[llength [get_ips -quiet $ip_name]] == 0} {
        create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name $ip_name
        set_property -dict [list \
            CONFIG.Memory_Type {True_Dual_Port_RAM} \
            CONFIG.Write_Width_A $width \
            CONFIG.Read_Width_A $width \
            CONFIG.Write_Width_B $width \
            CONFIG.Read_Width_B $width \
            CONFIG.Write_Depth_A $depth \
            CONFIG.Enable_A {Use_ENA_Pin} \
            CONFIG.Enable_B {Use_ENB_Pin} \
            CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
            CONFIG.Register_PortA_Output_of_Memory_Core {false} \
            CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
            CONFIG.Register_PortB_Output_of_Memory_Core {false} \
        ] [get_ips $ip_name]
        generate_target all [get_ips $ip_name]
    }
}

set snapshot_rtl_dir [file join $project_dir src rtl]
set snapshot_tb_dir  [file join $project_dir src tb]
set hex_dir [file normalize [file join $sr_core_dir generated_vivado_hex]]

add_source_if_missing [file join $snapshot_rtl_dir sr_top_clean_stream_img.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_ctrl_clean_stream_img.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_conv1_3x3_cin1_cout8_flat.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_conv1_to_conv3_stream_slice.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_conv1x1_cin8_cout4_flat.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_output_pack2x2_uint8.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_pctrl.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_window_3x3_cin1.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_conv3x3_cin1_cout8_mac.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_conv1x1_cin8_cout4_mac.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_requantize.v]
add_source_if_missing [file join $snapshot_rtl_dir pixel_shuffle_core.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_output_stage.v]
add_sim_if_missing    [file join $snapshot_tb_dir tb_sr_top_clean_stream_img.v]

create_single_port_rom_if_missing conv1_weight_rom 8  72 [file join $hex_dir conv1_weight.coe]
create_single_port_rom_if_missing conv3_weight_rom 8  32 [file join $hex_dir conv3_weight.coe]
create_single_port_rom_if_missing conv1_m0_rom     32 8  [file join $hex_dir conv1_m0.coe]
create_single_port_rom_if_missing conv1_m1_rom     64 8  [file join $hex_dir conv1_m1.coe]
create_single_port_rom_if_missing conv3_m0_rom     32 4  [file join $hex_dir conv3_m0.coe]
create_single_port_rom_if_missing conv3_m1_rom     64 4  [file join $hex_dir conv3_m1.coe]

# Final image output RAM. One 16-bit word stores two adjacent uint8 HR pixels.
create_true_dp_ram_if_missing output_image_ram 16 32768

set_property top sr_top_clean_stream_img [get_filesets sources_1]
set_property top tb_sr_top_clean_stream_img [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

launch_simulation -simset sim_1 -mode behavioral
run all
close_sim

close_project

puts "Phase9.6 clean streaming image-level SR simulation complete."
