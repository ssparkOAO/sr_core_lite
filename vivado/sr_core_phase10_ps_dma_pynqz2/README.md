# SR Core Phase10 PS/PL DMA Vivado 專案

這個資料夾預留給 Phase10 PS/PL DMA 整合專案。

它不可修改或重新產生：

- `model_lite/sr_core/vivado/sr_core_clean_stream_pynqz2/`

準備好建立專案時，使用 `tcl/` 裡的 Tcl script 產生新的 Vivado 專案。

## 預計專案設定

- 專案名稱：`sr_core_phase10_ps_dma_pynqz2`
- 板子：PYNQ-Z2
- Part：`xc7z020clg400-1`
- Block design：`sr_core_phase10_bd`

## 預計使用 IP

- ZYNQ7 Processing System
- AXI DMA
- AXI Interconnect 或 SmartConnect
- Processor System Reset
- 未來的 `sr_core_ps_dma_wrapper` module reference 或 packaged IP

## 目前狀態

目前是骨架資料夾。wrapper RTL 尚未實作，所以 Tcl script 只建立新專案並準備
block design/IP 結構，並用註解標出未來 wrapper 插入點。

Vivado 專案驗證要放在 Phase10 流程最後：wrapper source、IP 設定、拉線、
address map 都完成之後才驗證。
