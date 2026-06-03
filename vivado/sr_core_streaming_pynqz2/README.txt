sr_core_streaming_pynqz2 Vivado Project
=======================================

Purpose
-------
This Vivado project is for Phase9.4 BMG IP-backed verification and Phase9.5
image-level SR inference verification.

Phase9.5 is the current main flow.

Language
--------
Project target_language is Verilog.
Project simulator_language is Verilog.
The BMG IP simulation wrappers used by xsim are Verilog files under:
  sr_core_streaming_pynqz2.gen/sources_1/ip/*/sim/*.v

Source Snapshot
---------------
The current Vivado project uses a local source snapshot:

  src/rtl/*.v
  src/tb/tb_sr_nn_top_img.v

This snapshot exists so Vivado Sources can show the active top, submodules, and
testbench in one project-local folder.

It is not the golden source of truth.

Original source ownership remains:

  RTL/      -> Golden Verified RTL Module Library
  RTL_sys/  -> Architecture development workspace

If original RTL changes, refresh src/ and update:

  src/manifest/SOURCE_SNAPSHOT_MAP.txt
  ../../RTL_sys/MODULE_RELATIONSHIP_MAP.txt

Expected project contents
-------------------------
Design sources:
  src/rtl/*.v

Simulation source:
  src/tb/tb_sr_nn_top_img.v

Vivado BMG IP:
  conv1_weight_rom
  conv3_weight_rom
  conv1_m0_rom
  conv1_m1_rom
  conv3_m0_rom
  conv3_m1_rom
  conv3_feature_ram
  output_image_ram
  conv3_feature_ram_img
  output_image_ram_img

Relationship Map
----------------
For the complete top / TB / module / IP relationship map, read:

  ../../RTL_sys/MODULE_RELATIONSHIP_MAP.txt

For the snapshot source ownership map, read:

  src/manifest/SOURCE_SNAPSHOT_MAP.txt

Do not use this project to judge Phase9.3
-----------------------------------------
Phase9.3 uses:
  model_lite/sr_core/RTL_sys/phase9_3_ref_hier/sim/ram_ip_bhv.v

Phase9.4 uses:
  Vivado generated BMG IP simulation wrappers.

Phase9.5 uses:
  src/rtl/*.v
  src/tb/tb_sr_nn_top_img.v
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

Run image-level BMG IP-backed simulation:
  tcl/run_phase9_5_image_sim.tcl
