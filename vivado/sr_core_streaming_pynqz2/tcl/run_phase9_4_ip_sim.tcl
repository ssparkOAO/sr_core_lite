# Run Phase9.4 sr_nn_top verification with Vivado BMG IP simulation wrappers.

set script_dir [file dirname [file normalize [info script]]]
set project_dir [file normalize [file join $script_dir ..]]
set sr_core_dir [file normalize [file join $project_dir .. ..]]
set xpr_path [file join $project_dir sr_core_streaming_pynqz2.xpr]

open_project $xpr_path

set old_sim_tb [get_files -quiet [file join $sr_core_dir RTL_sys phase9_streaming_architecture tb_sr_core_top_stream_ram_wrapper.v]]
if {[llength $old_sim_tb] > 0} {
    remove_files -fileset sim_1 $old_sim_tb
}

set old_ip_tb [get_files -quiet [file join $sr_core_dir RTL_sys phase9_4_ip_verify tb_sr_nn_top_ip.v]]
if {[llength $old_ip_tb] > 0} {
    remove_files -fileset sim_1 $old_ip_tb
}

set ip_tb [file join $sr_core_dir RTL_sys phase9_4_ip_verify sim tb_sr_nn_top_ip.v]
if {[llength [get_files -quiet $ip_tb]] == 0} {
    add_files -fileset sim_1 -norecurse $ip_tb
}

set_property top sr_nn_top [get_filesets sources_1]
set_property top tb_sr_nn_top_ip [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

launch_simulation -simset sim_1 -mode behavioral
run all
close_sim

close_project

puts "Phase9.4 BMG IP-backed simulation complete."
