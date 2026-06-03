# Report Phase9.4 project language settings and generated IP source extensions.

set script_dir [file dirname [file normalize [info script]]]
set project_dir [file normalize [file join $script_dir ..]]
set xpr_path [file join $project_dir sr_core_streaming_pynqz2.xpr]

open_project $xpr_path

puts "Project target_language    = [get_property target_language [current_project]]"
puts "Project simulator_language = [get_property simulator_language [current_project]]"
puts ""
puts "IP list:"
foreach ip [lsort [get_ips]] {
    puts "  $ip"
}

puts ""
puts "Compile-order Verilog/VHDL files:"
foreach fs {sources_1 sim_1} {
    puts "Fileset $fs"
    foreach f [get_files -of_objects [get_filesets $fs]] {
        set ext [string tolower [file extension $f]]
        if {$ext == ".v" || $ext == ".vh" || $ext == ".sv" || $ext == ".vhd" || $ext == ".vhdl"} {
            puts "  $ext $f"
        }
    }
}

close_project
