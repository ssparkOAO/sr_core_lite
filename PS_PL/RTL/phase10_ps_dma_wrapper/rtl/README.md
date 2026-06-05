# Phase10 RTL 預留位置

未來 wrapper RTL 放在這裡。

預計模組：

- `sr_core_ps_dma_wrapper.v`

預計內部區塊：

- AXI-Lite control/status register block。
- AXI Stream input feeder。
- Phase9.6 `sr_top_clean_stream_img` instance。
- Output RAM stream reader。

Phase9.6 已驗證的 clean-stream core 保持不變。wrapper 只負責把 PS/DMA interface
轉接到既有 core ports。
