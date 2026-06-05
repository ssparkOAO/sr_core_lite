# Phase10 AXI-Stream Wrapper Simulation

This folder contains the Phase10 wrapper-level simulation flow.

## Run Command

Run from this folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_phase10_axis_wrapper_sim.ps1
```

## Important Simulation Rule

Use the Vivado BMG behavioral simulation wrappers from the Phase9.6 clean-stream
project:

```text
vivado/sr_core_clean_stream_pynqz2/sr_core_clean_stream_pynqz2.gen/sources_1/ip/*/sim/*.v
```

Do not use `*_sim_netlist.v` as the primary correctness source for this wrapper
debug flow. The netlist flow can be added later as a separate verification gate.

## Output Files

```text
RTL_sys/phase10_ps_dma_wrapper/results/tb_sr_core_axis_wrapper_result.txt
pic/test_pic/result/sr_output_uint8_axis_wrapper.txt
```

## PASS Conditions

```text
input count = 16384
input tlast index = 16383
core_done = 1
output count = 65536
output tlast index = 65535
mismatch count = 0
max abs diff = 0
PASS
```

The AXIS output txt should match:

```text
pic/test_pic/result/sr_output_uint8_clean_stream.txt
```
