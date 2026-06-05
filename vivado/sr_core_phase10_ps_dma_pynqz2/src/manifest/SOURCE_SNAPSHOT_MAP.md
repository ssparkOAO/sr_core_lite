# Phase10 Source Snapshot Map

用途：紀錄 `vivado/sr_core_phase10_ps_dma_pynqz2` 未來 Vivado source snapshot 的來源與責任邊界。

## 責任邊界

- `RTL/`：golden verified module library，Phase10 不修改。
- `RTL_sys/phase9_6_clean_stream/`：已驗證的 clean streaming architecture。
- `RTL_sys/phase10_ps_dma_wrapper/`：Phase10 PS/DMA wrapper workspace。
- `vivado/sr_core_phase10_ps_dma_pynqz2/src/`：Phase10 Vivado project-local snapshot。

## 預計 Snapshot

未來 wrapper：

- `src/rtl/sr_core_ps_dma_wrapper.v`
  - 原始位置：`RTL_sys/phase10_ps_dma_wrapper/rtl/sr_core_ps_dma_wrapper.v`
  - 用途：在 clean SR core 外層包 AXI-Lite control 和 AXI Stream DMA adapter。

Clean streaming core dependencies：

- `sr_top_clean_stream_img.v`
- `sr_ctrl_clean_stream_img.v`
- `sr_conv1_3x3_cin1_cout8_flat.v`
- `sr_conv1_to_conv3_stream_slice.v`
- `sr_conv1x1_cin8_cout4_flat.v`
- `sr_output_pack2x2_uint8.v`
- `sr_pctrl.v`
- `sr_window_3x3_cin1.v`
- `sr_conv3x3_cin1_cout8_mac.v`
- `sr_conv1x1_cin8_cout4_mac.v`
- `sr_requantize.v`
- `pixel_shuffle_core.v`
- `sr_output_stage.v`

預期 Vivado memory IP：

- `conv1_weight_rom`
- `conv3_weight_rom`
- `conv1_m0_rom`
- `conv1_m1_rom`
- `conv3_m0_rom`
- `conv3_m1_rom`
- `output_image_ram`

## 安全規則

不要為了刷新這份 snapshot 去編輯既有 clean-stream Vivado 專案。
只能從已驗證 source locations 複製到這個 Phase10 專案資料夾。
