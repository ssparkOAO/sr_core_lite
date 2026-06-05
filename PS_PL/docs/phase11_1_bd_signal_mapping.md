# Phase11.1 Block Design Signal Mapping

## Target Block Design

```text
PS DDR Input Buffer
-> AXI DMA MM2S
-> SR Accelerator IP S_AXIS
-> SR Accelerator IP M_AXIS
-> AXI DMA S2MM
-> PS DDR Output Buffer
```

## BD Cells

```text
zynq_ps
axi_dma_0
rst_ps7_0_100M
sr_accel_axis_0
smartconnect_mem
```

## Stream Connections

| Source | Sink | Meaning |
|---|---|---|
| `axi_dma_0/M_AXIS_MM2S` | `sr_accel_axis_0/S_AXIS` | PS DDR input buffer streams LR pixels into PL. |
| `sr_accel_axis_0/M_AXIS` | `axi_dma_0/S_AXIS_S2MM` | SR output stream returns to PS DDR output buffer. |

## Clock Connections

All Phase11.1 logic uses the PS fabric clock:

```text
zynq_ps/FCLK_CLK0
```

Connect to:

```text
axi_dma_0/s_axi_lite_aclk
axi_dma_0/m_axi_mm2s_aclk
axi_dma_0/m_axi_s2mm_aclk
sr_accel_axis_0/aclk
rst_ps7_0_100M/slowest_sync_clk
```

## Reset Connections

Use Processor System Reset:

```text
zynq_ps/FCLK_RESET0_N
-> rst_ps7_0_100M/ext_reset_in
```

Generated active-low reset:

```text
rst_ps7_0_100M/peripheral_aresetn
-> axi_dma_0/axi_resetn
-> sr_accel_axis_0/aresetn
```

## Memory-Mapped AXI Connections

DMA control:

```text
zynq_ps/M_AXI_GP0
-> AXI interconnect / SmartConnect
-> axi_dma_0/S_AXI_LITE
```

DMA data movement:

```text
axi_dma_0/M_AXI_MM2S
-> smartconnect_mem/S00_AXI
-> smartconnect_mem/M00_AXI
-> zynq_ps/S_AXI_HP0

axi_dma_0/M_AXI_S2MM
-> smartconnect_mem/S01_AXI
-> smartconnect_mem/M00_AXI
-> zynq_ps/S_AXI_HP0
```

Phase11.1 intentionally uses SmartConnect for this memory path instead of AXI Interconnect.

## Address Assignment

Run:

```tcl
assign_bd_address
```

PASS condition:

```text
AXI DMA S_AXI_LITE receives an address range.
No unassigned address segments remain.
```

## Not Included Yet

Phase11.1 does not include:

```text
AXI-Lite custom control registers
Interrupts
Python runtime
Board DMA transfer test
HDMI / camera
```

Those belong to Phase11.2 and later.
