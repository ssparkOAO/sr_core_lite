# Phase8.3 quick behavioral simulation for parameter ROM bank.
#
# Run this from Vivado with:
#   vivado -mode batch -source run_bram_param_bank_behavioral_sim.tcl
#
# This simulation uses sim/param_rom_behavioral_models.v. The generated Vivado IP
# simulation models can be used later after IP generation is complete.

set script_dir [file dirname [file normalize [info script]]]
set phase_dir  [file normalize [file join $script_dir ..]]
set sim_dir    [file normalize [file join $phase_dir sim]]
set rtl_dir    [file normalize [file join $phase_dir rtl]]

cd $sim_dir

exec xvlog ../sim/param_rom_behavioral_models.v ../rtl/sr_param_rom_bank.v ../sim/tb_sr_param_rom_bank.v
exec xelab tb_sr_param_rom_bank -debug typical -s tb_sr_param_rom_bank_snapshot
exec xsim tb_sr_param_rom_bank_snapshot -runall

puts "============================================================"
puts "Phase8.3 behavioral parameter ROM bank simulation finished."
puts "Result file: [file join $sim_dir tb_sr_param_rom_bank_result.txt]"
puts "============================================================"
