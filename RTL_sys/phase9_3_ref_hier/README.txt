Phase9.3 Reference-Like CNN Hierarchy
====================================

This folder is the behavioral-model verification workspace.

Folder layout
-------------
rtl/
  Real Phase9.3 hierarchy RTL:
  sr_nn_top, sr_ctrl, sr_pctrl, sr_c1c3_slice, sr_out_pack.

sim/
  Behavioral-only simulation files:
  tb_sr_nn_top.v and ram_ip_bhv.v.
  This does not prove Vivado BMG IP usage.

results/
  Behavioral PASS result and dumps.

work/
  xsim generated logs, snapshots, and waveform database files.
  .wdb is a waveform database opened by Vivado/xsim. It is not RTL source.

Important distinction
---------------------
Phase9.3 checks the new hierarchy and controller behavior with ram_ip_bhv.v.
Phase9.4 checks the same sr_nn_top with real Vivado BMG IP simulation wrappers.

