Phase9.4 BMG IP-Backed Verification
===================================

This folder contains the IP-backed testbench and results.

Folder layout
-------------
sim/
  tb_sr_nn_top_ip.v
  This testbench is used inside:
  model_lite/sr_core/vivado/sr_core_streaming_pynqz2/sr_core_streaming_pynqz2.xpr

results/
  IP-backed verification result and dumps.

What is actually tested
-----------------------
sr_nn_top uses the real Vivado BMG simulation wrappers from the Vivado project:
conv1_weight_rom, conv3_weight_rom, conv1_m0_rom, conv1_m1_rom,
conv3_m0_rom, conv3_m1_rom, conv3_feature_ram, output_image_ram.

Run flow
--------
First clean the project source membership:
C:\Xilinx\Vivado\2023.1\bin\vivado.bat -mode batch -source model_lite/sr_core/vivado/sr_core_streaming_pynqz2/tcl/clean_phase9_4_project.tcl

Then run IP-backed simulation:
C:\Xilinx\Vivado\2023.1\bin\vivado.bat -mode batch -source model_lite/sr_core/vivado/sr_core_streaming_pynqz2/tcl/run_phase9_4_ip_sim.tcl

