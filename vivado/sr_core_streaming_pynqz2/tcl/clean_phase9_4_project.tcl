# Keep only the Phase9.4 IP-backed verification files in the existing project.

set script_dir [file dirname [file normalize [info script]]]
set project_dir [file normalize [file join $script_dir ..]]
set sr_core_dir [file normalize [file join $project_dir .. ..]]
set xpr_path [file join $project_dir sr_core_streaming_pynqz2.xpr]

open_project $xpr_path

set remove_list [list \
    [file join $sr_core_dir RTL_sys phase8_3_vivado_bram rtl sr_param_rom_bank.v] \
    [file join $sr_core_dir RTL_sys phase9_streaming_architecture phase9_behavioral_ram_models.v] \
    [file join $sr_core_dir RTL_sys phase9_streaming_architecture tb_sr_core_top_stream_ram_wrapper.v] \
    [file join $sr_core_dir RTL_sys phase9_3_ref_hier sr_pctrl.v] \
    [file join $sr_core_dir RTL_sys phase9_3_ref_hier sr_ctrl.v] \
    [file join $sr_core_dir RTL_sys phase9_3_ref_hier sr_c1c3_slice.v] \
    [file join $sr_core_dir RTL_sys phase9_3_ref_hier sr_out_pack.v] \
    [file join $sr_core_dir RTL_sys phase9_3_ref_hier sr_nn_top.v] \
    [file join $sr_core_dir RTL_sys phase9_3_ref_hier tb_sr_nn_top_ip.v] \
    [file join $sr_core_dir RTL_sys phase9_4_ip_verify tb_sr_nn_top_ip.v] \
]

foreach f $remove_list {
    set matches [get_files -quiet $f]
    if {[llength $matches] > 0} {
        remove_files $matches
    }
}

set phase9_3_sources [list \
    [file join $sr_core_dir RTL_sys phase9_3_ref_hier rtl sr_pctrl.v] \
    [file join $sr_core_dir RTL_sys phase9_3_ref_hier rtl sr_ctrl.v] \
    [file join $sr_core_dir RTL_sys phase9_3_ref_hier rtl sr_c1c3_slice.v] \
    [file join $sr_core_dir RTL_sys phase9_3_ref_hier rtl sr_out_pack.v] \
    [file join $sr_core_dir RTL_sys phase9_3_ref_hier rtl sr_nn_top.v] \
]

foreach f $phase9_3_sources {
    if {[llength [get_files -quiet $f]] == 0} {
        add_files -norecurse $f
    }
}

set ip_tb [file join $sr_core_dir RTL_sys phase9_4_ip_verify sim tb_sr_nn_top_ip.v]
if {[llength [get_files -quiet $ip_tb]] == 0} {
    add_files -fileset sim_1 -norecurse $ip_tb
}

set_property top sr_nn_top [get_filesets sources_1]
set_property top tb_sr_nn_top_ip [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

close_project

puts "Cleaned sr_core_streaming_pynqz2 for Phase9.4 IP-backed verification."
