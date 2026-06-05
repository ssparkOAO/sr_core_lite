# Phase10 Signal Map

這份檔案只記 `sr_core_ps_dma_wrapper` 的 interface 小抄。
完整學習說明請看 `html/phase10_ps_dma_wrapper_plan.html`。

## Wrapper Port Plan

| Port | Direction | 用途 |
|---|---|---|
| `aclk` | input | wrapper、AXI-Lite、AXI Stream 使用同一個 clock。 |
| `aresetn` | input | active-low reset。 |
| `S_AXI` | slave | PS 寫 control/status register。 |
| `S_AXIS` | slave | AXI DMA MM2S 送 128x128 input。 |
| `M_AXIS` | master | wrapper 送 256x256 output 到 AXI DMA S2MM。 |

## AXI-Lite Register Map

| Offset | Name | Access | 用途 |
|---:|---|---|---|
| `0x00` | `CTRL` | RW | bit0 soft reset，bit1 preload pulse，bit2 start pulse，bit3 clear done |
| `0x04` | `STATUS` | RO | bit0 preload_busy，bit1 preload_done，bit2 core_busy，bit3 core_done，bit4 input_done，bit5 output_done |
| `0x08` | `INPUT_COUNT` | RO | 已接收 input bytes，預期 16384 |
| `0x0C` | `OUTPUT_COUNT` | RO | 已送出 output bytes，預期 65536 |
| `0x10` | `ERROR` | RO/W1C | bit0 input overflow，bit1 early tlast，bit2 missing tlast，bit3 output underflow |

## Stream Format

| Stream | Source | Sink | Size | Format |
|---|---|---|---:|---|
| Input | AXI DMA MM2S | wrapper `S_AXIS` | 16384 bytes | 128x128 uint8 grayscale |
| Output | wrapper `M_AXIS` | AXI DMA S2MM | 65536 bytes | 256x256 uint8 grayscale |

## Core Adapter Notes

- 內部 core：`sr_top_clean_stream_img`
- input conversion：`signed_int8 = uint8 - 128`
- output RAM words：32768
- output RAM word format：`{right_uint8, left_uint8}`
- stream order：每個 RAM word 先送 left byte，再送 right byte
