# Phase11.1 IP Packaging Notes

## Goal

Package the verified Phase10 AXI4-Stream wrapper as a Vivado IP for later AXI DMA integration.

The packaged top is:

```text
PS_PL/RTL/phase11_1_dma_block_design/rtl/sr_accel_axis_ip_top.v
```

It wraps:

```text
PS_PL/RTL/phase10_ps_dma_wrapper/rtl/sr_core_axis_wrapper.v
```

## Frozen Core Boundary

Do not modify:

```text
RTL_sys/phase9_6_clean_stream/
vivado/sr_core_clean_stream_pynqz2/
```

Phase11.1 uses the PS_PL copy/snapshot as packaging input and keeps the verified wrapper behavior unchanged.

## External IP Ports

```text
aclk
aresetn

s_axis_tdata[7:0]
s_axis_tkeep[0:0]
s_axis_tvalid
s_axis_tready
s_axis_tlast

m_axis_tdata[7:0]
m_axis_tkeep[0:0]
m_axis_tvalid
m_axis_tready
m_axis_tlast
```

## Reset Polarity

Vivado BD convention:

```text
aresetn = active-low reset
```

Verified wrapper convention:

```text
rst = active-high reset
```

The packaging shell bridges them:

```verilog
assign rst = ~aresetn;
```

## AXI4-Stream Interface Mapping

S_AXIS:

```text
s_axis_tdata
s_axis_tkeep
s_axis_tvalid
s_axis_tready
s_axis_tlast
associated clock = aclk
associated reset = aresetn
```

M_AXIS:

```text
m_axis_tdata
m_axis_tkeep
m_axis_tvalid
m_axis_tready
m_axis_tlast
associated clock = aclk
associated reset = aresetn
```

`m_axis_tkeep` is fixed to `1'b1` because the stream width is 8-bit and every valid beat contains one pixel byte.

## GUI Rebuild Notes

1. Open Vivado.
2. Create project `sr_core_phase11_dma_pynqz2`.
3. Add the Phase11.1 packaging shell and required SR core RTL sources.
4. Add the existing clean-stream BMG XCI files.
5. Go to `Tools -> Create and Package New IP`.
6. Choose `Package your current project`.
7. Set vendor/library/name/version:

```text
vendor  = user.org
library = user
name    = sr_accel_axis_ip
version = 1.0
```

8. In `Ports and Interfaces`, infer or manually map:

```text
S_AXIS
M_AXIS
aclk
aresetn
```

9. Review and package IP.

Equivalent Tcl is captured in:

```text
PS_PL/vivado/sr_core_phase11_dma_pynqz2/tcl/run_phase11_1_create_dma_bd.tcl
```

## Important Limitation

Phase11.1 does not add AXI-Lite status/control registers. The wrapper still auto-preloads and runs as defined by the verified Phase10 wrapper flow.

## Phase11.1 Result

```text
VALIDATE_PASS
SYNTH_STATUS: synth_design Complete!
SYNTH_PASS
Phase11.1 result: PASS
```

The packaged IP was recognized with inferred AXI4-Stream slave and master interfaces. The final Block Design uses SmartConnect on the DMA memory path.
