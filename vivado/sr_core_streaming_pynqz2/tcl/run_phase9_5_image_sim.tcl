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

add_source_if_missing [file join $sr_core_dir RTL_sys phase9_5_image_test rtl sr_ctrl_img.v]
add_source_if_missing [file join $sr_core_dir RTL_sys phase9_5_image_test rtl sr_c1c3_slice_img.v]
add_source_if_missing [file join $sr_core_dir RTL_sys phase9_5_image_test rtl sr_out_pack_img.v]
add_source_if_missing [file join $sr_core_dir RTL_sys phase9_5_image_test rtl sr_nn_top_img.v]
add_sim_if_missing    [file join $sr_core_dir RTL_sys phase9_5_image_test sim tb_sr_nn_top_img.v]

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
