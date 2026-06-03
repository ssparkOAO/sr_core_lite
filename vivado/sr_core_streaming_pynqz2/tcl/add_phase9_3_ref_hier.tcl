# Add Phase9.3 reference-like hierarchy sources to the existing streaming project.

set script_dir [file dirname [file normalize [info script]]]
set project_dir [file normalize [file join $script_dir ..]]
set sr_core_dir [file normalize [file join $project_dir .. ..]]
set xpr_path [file join $project_dir sr_core_streaming_pynqz2.xpr]

open_project $xpr_path

add_files -norecurse [file join $sr_core_dir RTL_sys phase9_3_ref_hier rtl sr_pctrl.v]
add_files -norecurse [file join $sr_core_dir RTL_sys phase9_3_ref_hier rtl sr_ctrl.v]
add_files -norecurse [file join $sr_core_dir RTL_sys phase9_3_ref_hier rtl sr_c1c3_slice.v]
add_files -norecurse [file join $sr_core_dir RTL_sys phase9_3_ref_hier rtl sr_out_pack.v]
add_files -norecurse [file join $sr_core_dir RTL_sys phase9_3_ref_hier rtl sr_nn_top.v]

set_property top sr_nn_top [get_filesets sources_1]
update_compile_order -fileset sources_1

close_project

puts "Phase9.3 reference-like hierarchy added. sources_1 top = sr_nn_top"
