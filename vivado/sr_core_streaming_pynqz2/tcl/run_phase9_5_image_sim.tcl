# Run Phase9.5 image-level SR inference simulation with Vivado BMG IP.

set script_dir [file dirname [file normalize [info script]]]
set project_dir [file normalize [file join $script_dir ..]]
set sr_core_dir [file normalize [file join $project_dir .. ..]]
set xpr_path [file join $project_dir sr_core_streaming_pynqz2.xpr]

open_project $xpr_path

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

proc remove_file_if_present {path} {
    set files [get_files -quiet $path]
    if {[llength $files] != 0} {
        remove_files $files
    }
}

proc create_image_simple_dp_ram_if_missing {ip_name width depth} {
    if {[llength [get_ips -quiet $ip_name]] == 0} {
        create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name $ip_name
        set_property -dict [list \
            CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
            CONFIG.Write_Width_A $width \
            CONFIG.Read_Width_A $width \
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

proc create_image_true_dp_ram_if_missing {ip_name width depth} {
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

# Phase9.5 now uses the Vivado project source snapshot under src/.
# Remove older distributed references so the Vivado Sources window is easier to read.
remove_file_if_present [file join $sr_core_dir RTL_sys phase9_5_image_test rtl sr_ctrl_img.v]
remove_file_if_present [file join $sr_core_dir RTL_sys phase9_5_image_test rtl sr_c1c3_slice_img.v]
remove_file_if_present [file join $sr_core_dir RTL_sys phase9_5_image_test rtl sr_out_pack_img.v]
remove_file_if_present [file join $sr_core_dir RTL_sys phase9_5_image_test rtl sr_nn_top_img.v]
remove_file_if_present [file join $sr_core_dir RTL_sys phase9_5_image_test sim tb_sr_nn_top_img.v]
remove_file_if_present [file join $sr_core_dir RTL_sys phase9_3_ref_hier rtl sr_pctrl.v]
remove_file_if_present [file join $sr_core_dir RTL sr_conv1_3x3_cin1_cout8_block sr_conv1_3x3_cin1_cout8_block.v]
remove_file_if_present [file join $sr_core_dir RTL sr_conv3x3_cin1_cout8_mac sr_window_3x3_cin1.v]
remove_file_if_present [file join $sr_core_dir RTL sr_conv3x3_cin1_cout8_mac sr_conv3x3_cin1_cout8_mac.v]
remove_file_if_present [file join $sr_core_dir RTL sr_conv1x1_cin8_cout4_block sr_conv1x1_cin8_cout4_block.v]
remove_file_if_present [file join $sr_core_dir RTL sr_conv1x1_cin8_cout4_mac sr_conv1x1_cin8_cout4_mac.v]
remove_file_if_present [file join $sr_core_dir RTL sr_requantize sr_requantize.v]
remove_file_if_present [file join $sr_core_dir RTL sr_pixel_shuffle_x2 pixel_shuffle_core.v]
remove_file_if_present [file join $sr_core_dir RTL sr_output_stage sr_output_stage.v]
remove_file_if_present [file join $sr_core_dir RTL_sys phase9_3_ref_hier rtl sr_c1c3_slice.v]
remove_file_if_present [file join $sr_core_dir RTL_sys phase9_3_ref_hier rtl sr_ctrl.v]
remove_file_if_present [file join $sr_core_dir RTL_sys phase9_3_ref_hier rtl sr_out_pack.v]
remove_file_if_present [file join $sr_core_dir RTL_sys phase9_3_ref_hier rtl sr_nn_top.v]
remove_file_if_present [file join $sr_core_dir RTL_sys phase9_4_ip_verify sim tb_sr_nn_top_ip.v]

add_source_if_missing [file join $snapshot_rtl_dir sr_nn_top_img.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_ctrl_img.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_c1c3_slice_img.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_out_pack_img.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_pctrl.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_conv1_3x3_cin1_cout8_block.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_window_3x3_cin1.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_conv3x3_cin1_cout8_mac.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_conv1x1_cin8_cout4_block.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_conv1x1_cin8_cout4_mac.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_requantize.v]
add_source_if_missing [file join $snapshot_rtl_dir pixel_shuffle_core.v]
add_source_if_missing [file join $snapshot_rtl_dir sr_output_stage.v]
add_sim_if_missing    [file join $snapshot_tb_dir tb_sr_nn_top_img.v]

create_image_simple_dp_ram_if_missing conv3_feature_ram_img 32 16384
create_image_true_dp_ram_if_missing   output_image_ram_img 16 32768

set_property top sr_nn_top_img [get_filesets sources_1]
set_property top tb_sr_nn_top_img [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

launch_simulation -simset sim_1 -mode behavioral
run all
close_sim

close_project

puts "Phase9.5 image-level SR inference simulation complete."
