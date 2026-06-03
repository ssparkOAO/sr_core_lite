sr_core_streaming_pynqz2 Vivado Project
=======================================

Purpose
-------
This Vivado project is for Phase9.4 BMG IP-backed verification.
It is not the Phase9.3 behavioral-only test.

Language
--------
Project target_language is Verilog.
Project simulator_language is Verilog.
The BMG IP simulation wrappers used by xsim are Verilog files under:
  sr_core_streaming_pynqz2.gen/sources_1/ip/*/sim/*.v

Expected project contents
-------------------------
Design sources:
  model_lite/sr_core/RTL_sys/phase9_3_ref_hier/rtl/*.v
  model_lite/sr_core/RTL/* verified module dependencies

Simulation source:
  model_lite/sr_core/RTL_sys/phase9_4_ip_verify/sim/tb_sr_nn_top_ip.v

Vivado BMG IP:
  conv1_weight_rom
  conv3_weight_rom
  conv1_m0_rom
  conv1_m1_rom
  conv3_m0_rom
  conv3_m1_rom
  conv3_feature_ram
  output_image_ram

Do not use this project to judge Phase9.3
-----------------------------------------
Phase9.3 uses:
  model_lite/sr_core/RTL_sys/phase9_3_ref_hier/sim/ram_ip_bhv.v

Phase9.4 uses:
  Vivado generated BMG IP simulation wrappers.

Useful Tcl
----------
Clean project source membership:
  tcl/clean_phase9_4_project.tcl

Force Verilog project language and regenerate current IP output products:
  tcl/set_ip_verilog_and_regen.tcl

Report project language and compile-order source extensions:
  tcl/report_ip_language.tcl

Run BMG IP-backed simulation:
  tcl/run_phase9_4_ip_sim.tcl
