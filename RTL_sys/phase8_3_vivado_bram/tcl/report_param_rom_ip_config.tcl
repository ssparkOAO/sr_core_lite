# Report Phase8.3 / Phase8.4 parameter ROM IP configuration.
#
# This script only inspects the existing Vivado project. It does not modify IPs.

set script_dir  [file dirname [file normalize [info script]]]
set phase_dir   [file normalize [file join $script_dir ..]]
set sr_core_dir [file normalize [file join $phase_dir .. ..]]
set proj_dir    [file normalize [file join $sr_core_dir vivado sr_core_bram_pynqz2]]
set project_xpr [file join $proj_dir sr_core_bram_pynqz2.xpr]
set report_path [file normalize [file join $phase_dir sim param_rom_ip_config_report.txt]]

open_project $project_xpr

set fp [open $report_path "w"]

puts $fp "Phase8.4 Parameter ROM IP Configuration Report"
puts $fp "Project: $project_xpr"
puts $fp ""

set ip_names [list \
    conv1_weight_rom \
    conv3_weight_rom \
    conv1_m0_rom \
    conv1_m1_rom \
    conv3_m0_rom \
    conv3_m1_rom \
]

set keys [list \
    Memory_Type \
    Write_Width_A \
    Read_Width_A \
    Write_Depth_A \
    Enable_A \
    Register_PortA_Output_of_Memory_Primitives \
    Register_PortA_Output_of_Memory_Core \
    Load_Init_File \
    Coe_File \
]

foreach ip_name $ip_names {
    set ip_obj [get_ips $ip_name]
    puts $fp "IP: $ip_name"

    foreach key $keys {
        set prop_name "CONFIG.${key}"
        if {[lsearch -exact [list_property $ip_obj] $prop_name] >= 0} {
            puts $fp "  $key = [get_property $prop_name $ip_obj]"
        } else {
            puts $fp "  $key = <not available>"
        }
    }

    set read_width [get_property CONFIG.Read_Width_A $ip_obj]
    set write_depth [get_property CONFIG.Write_Depth_A $ip_obj]
    set address_width [expr {int(ceil(log($write_depth) / log(2)))}]

    puts $fp "  Address_Width_Calculated = $address_width"
    puts $fp "  Read_Latency_Interpretation = 1 clock from synchronous ROM memory primitive"
    puts $fp ""
}

close $fp

puts "Report written to $report_path"
