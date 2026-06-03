# Force the existing Phase9.4 streaming Vivado project to prefer Verilog
# generated IP wrappers and regenerate current BMG output products.

set script_dir [file dirname [file normalize [info script]]]
set project_dir [file normalize [file join $script_dir ..]]
set xpr_path [file join $project_dir sr_core_streaming_pynqz2.xpr]

open_project $xpr_path

set_property target_language Verilog [current_project]
set_property simulator_language Verilog [current_project]

generate_target all [get_ips]
export_ip_user_files -of_objects [get_ips] -no_script -sync -force -quiet

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

close_project

puts "Updated sr_core_streaming_pynqz2 to prefer Verilog IP output products."
