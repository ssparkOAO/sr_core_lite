# Phase8.3 Vivado ROM Parameter Architecture
# Project: sr_core_bram_pynqz2
#
# This script creates a Vivado project and six Block Memory Generator ROM IPs:
#   1. conv1_weight_rom
#   2. conv3_weight_rom
#   3. conv1_m0_rom
#   4. conv1_m1_rom
#   5. conv3_m0_rom
#   6. conv3_m1_rom
#
# Scope:
#   parameter ROM prototype only. No AXI, DMA, PS, PS-PL, or streaming refactor.

set script_dir  [file dirname [file normalize [info script]]]
set phase_dir   [file normalize [file join $script_dir ..]]
set sr_core_dir [file normalize [file join $phase_dir .. ..]]
set proj_dir    [file normalize [file join $sr_core_dir vivado sr_core_bram_pynqz2]]
set coe_dir     [file normalize [file join $sr_core_dir generated_vivado_hex]]
set rtl_dir     [file normalize [file join $phase_dir rtl]]

set project_name sr_core_bram_pynqz2
set part_name xc7z020clg400-1

file mkdir $proj_dir

if {[file exists [file join $proj_dir "${project_name}.xpr"]]} {
    open_project [file join $proj_dir "${project_name}.xpr"]
} else {
    create_project $project_name $proj_dir -part $part_name
}

proc set_ip_config_if_exists {ip_obj key value} {
    set prop_name "CONFIG.${key}"
    if {[lsearch -exact [list_property $ip_obj] $prop_name] >= 0} {
        set_property $prop_name $value $ip_obj
    } else {
        puts "WARNING: ${prop_name} is not available on this IP version."
    }
}

proc append_ip_config_if_exists {cfg_var ip_obj key value} {
    upvar $cfg_var cfg
    set prop_name "CONFIG.${key}"
    if {[lsearch -exact [list_property $ip_obj] $prop_name] >= 0} {
        lappend cfg $prop_name $value
    } else {
        puts "WARNING: ${prop_name} is not available on this IP version."
    }
}

proc create_single_port_rom {module_name width depth coe_file} {
    if {[llength [get_ips -quiet $module_name]] == 0} {
        create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name $module_name
    }

    set ip_obj [get_ips $module_name]

    # Block Memory Generator validates related parameters immediately.
    # Load_Init_File and Coe_File must be applied together.
    set cfg [list]
    append_ip_config_if_exists cfg $ip_obj Memory_Type Single_Port_ROM
    append_ip_config_if_exists cfg $ip_obj Write_Width_A $width
    append_ip_config_if_exists cfg $ip_obj Read_Width_A $width
    append_ip_config_if_exists cfg $ip_obj Write_Depth_A $depth
    append_ip_config_if_exists cfg $ip_obj Read_Depth_A $depth
    append_ip_config_if_exists cfg $ip_obj Load_Init_File true
    append_ip_config_if_exists cfg $ip_obj Coe_File $coe_file
    append_ip_config_if_exists cfg $ip_obj Enable_A Use_ENA_Pin
    append_ip_config_if_exists cfg $ip_obj Use_Byte_Write_Enable false
    append_ip_config_if_exists cfg $ip_obj Register_PortA_Output_of_Memory_Primitives false
    append_ip_config_if_exists cfg $ip_obj Register_PortA_Output_of_Memory_Core false
    append_ip_config_if_exists cfg $ip_obj Use_RSTA_Pin false

    set_property -dict $cfg $ip_obj

    generate_target all $ip_obj
}

create_single_port_rom conv1_weight_rom 8  72 [file join $coe_dir conv1_weight.coe]
create_single_port_rom conv3_weight_rom 8  32 [file join $coe_dir conv3_weight.coe]
create_single_port_rom conv1_m0_rom     32 8  [file join $coe_dir conv1_m0.coe]
create_single_port_rom conv1_m1_rom     64 8  [file join $coe_dir conv1_m1.coe]
create_single_port_rom conv3_m0_rom     32 4  [file join $coe_dir conv3_m0.coe]
create_single_port_rom conv3_m1_rom     64 4  [file join $coe_dir conv3_m1.coe]

add_files -norecurse [file join $rtl_dir sr_param_rom_bank.v]
update_compile_order -fileset sources_1

puts "============================================================"
puts "Phase8.3 ROM IP project created/updated."
puts "Project: $proj_dir"
puts "IP count: [llength [get_ips]]"
puts "============================================================"
