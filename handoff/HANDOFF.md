# SR Core Handoff

This handoff is for the `model_lite/sr_core` FPGA-based Super Resolution accelerator RTL project.

The project has moved from module-level RTL verification into system architecture refactor work. Treat this file as the first document to read before continuing the project.

## Quick Start For A New Chat

Read these first, in this order:

```text
handoff/HANDOFF.md
RTL_sys/MODULE_RELATIONSHIP_MAP.txt
vivado/sr_core_streaming_pynqz2/src/manifest/SOURCE_SNAPSHOT_MAP.txt
vivado/sr_core_streaming_pynqz2/README.txt
```

Use these project skills when relevant:

```text
skill/sr-accelerator-rtl-flow/SKILL.md
skill/sr-token-efficient-workflow/SKILL.md
skill/sr-core-chat-handoff-flow/SKILL.md
skill/vivado-ip-gui-doc-flow/SKILL.md
```

Most future prompts should not paste the full project history. Use a short prompt:

```text
This is model_lite/sr_core.
Please read the handoff and relationship maps first.
Current task: <one sentence>
Allowed files: <paths>
Verification level: Level <0-4>
Do not modify RTL/ golden modules unless explicitly requested.
```

## Verification Level Guide

Use the smallest level that proves the change:

| Level | Use For | Vivado? |
|---:|---|---|
| 0 | HTML, handoff, skill, README, manifest-only edits | No |
| 1 | Python tools, generated text checks, encoding checks | No |
| 2 | One small RTL/TB module verification | Maybe xsim only |
| 3 | Phase9.5 image-level Vivado simulation | Yes |
| 4 | Vivado synthesis, schematic, timing, hierarchy inspection | Yes |

Current expensive checkpoint:

```text
Phase9.5 image-level Vivado simulation
```

Run it only when touching the streaming Vivado top, controller, RAM/IP wiring, Tcl source membership, or image-level TB flow.

## Project Summary

This project implements a runtime-verified quantized Super Resolution accelerator RTL flow.

The model path is:

```text
Bilinear_PP_v5_test_qat.tflite
```

The verified tensor flow is:

```text
input_uint8
-> QUANTIZE
-> input_int8_for_core
-> Conv1 3x3, Cin=1, Cout=8
-> Requant + fused ReLU behavior
-> Conv3 1x1, Cin=8, Cout=4
-> Requant
-> PixelShuffle x2
-> Output Stage, int8 to uint8
-> output_uint8
```

The golden flow is trusted because the NumPy reconstructed quantized flow and real TensorFlow Lite runtime were previously verified bit-exact.

## Current PASS Status

The following phases are complete and verified:

| Phase | Module / Work | Status |
|---|---|---|
| Phase1 | `sr_requantize` | PASS |
| Phase2 | `sr_conv1x1_cin8_cout4_mac` | PASS |
| Phase2.5 | `sr_conv1x1_cin8_cout4_block` | PASS |
| Phase3 | `pixel_shuffle_core` | PASS |
| Phase4 | `sr_window_3x3_cin1` + `sr_conv3x3_cin1_cout8_mac` | PASS |
| Phase4.5 | `sr_conv1_3x3_cin1_cout8_block` | PASS |
| Phase5 / Phase6 | `sr_output_stage` | PASS |
| Phase7 | `sr_core_top` end-to-end verification | PASS |
| Phase8.1 | Weight Memory Self-Check | PASS |
| Phase8.2 | Memory-Oriented Top Wrapper | PASS |
| Phase8.3 | Parameter ROM Prototype | PASS |
| Phase8.4a | ROM Timing Analysis | PASS |
| Phase8.4b | ROM Preload Wrapper Integration | PASS |
| Phase9.1 | Conv1 to Conv3 Streaming Architecture Analysis | Analysis Complete |
| Phase9.2 | Reference-like RAM/IP Architecture | PASS |
| Phase9.3 | Reference-like CNN Hierarchy | PASS |
| Phase9.4 | BMG IP-backed Verification | PASS |
| Phase9.5 | Image-Level SR Inference Test | PASS |
| Phase9.6 | Clean Streaming CNN / RAM Architecture | PASS |

Latest end-to-end Phase8.4b result:

```text
preload_done asserted
mismatch count = 0
max abs diff   = 0
PASS
```

Latest Phase9.1 analysis result:

```text
feature_mem0 can be eliminated.
Conv3 is 1x1 and only needs the same pixel's 8-channel Conv1 output.
First streaming refactor should use conv1_out_valid + q0~q7 + x/y.
No FIFO is required for the first version.
A register slice is recommended.
```

Latest Phase9.2 result:

```text
Conv1 -> Conv3 streaming is implemented in RTL_sys.
feature_mem0 is removed.
conv3_feature_ram is exposed as a raw RAM port.
output_image_ram is exposed as a raw RAM port.

conv3_feature_ram mismatch count = 0
output_image_ram mismatch count = 0
total mismatch count = 0
max abs diff = 0
PASS
```

Latest Phase9.5 image-level result:

```text
Vivado IP-backed TB:
  TB_CAPTURE_PASS
  input sent count = 16384
  output pixel count = 65536

RTL output vs software golden:
  mismatch count = 0
  max abs diff = 0
  PASS

Image quality:
  SR vs HR PSNR       = 27.921916 dB
  Bilinear vs HR PSNR = 25.995107 dB
```

Latest Phase9.6 clean streaming result:

```text
Vivado IP-backed TB:
  input sent count = 16384
  output pixel count = 65536

Clean stream output vs Phase9.5 output:
  mismatch count = 0
  max abs diff = 0
  PASS
```

## Workspace Rules

### Golden Verified RTL

Do not modify this folder unless explicitly requested:

```text
model_lite/sr_core/RTL/
```

This folder is the Golden Verified RTL Module Library.

It contains modules such as:

```text
sr_requantize
sr_window_3x3_cin1
sr_conv3x3_cin1_cout8_mac
sr_conv1_3x3_cin1_cout8_block
sr_conv1x1_cin8_cout4_mac
sr_conv1x1_cin8_cout4_block
pixel_shuffle_core
sr_output_stage
sr_core_top
```

### System Architecture Workspace

New architecture refactor work goes here:

```text
model_lite/sr_core/RTL_sys/
```

This is where Weight Memory Refactor, ROM/BRAM work, streaming refactor, AXI, DMA, and PS-PL integration should be developed.

### Documentation Workspace

Project documentation goes here:

```text
model_lite/sr_core/html/
```

Main documents:

```text
html/index.html
html/rtl/index.html
html/RTL_sys_index.html
html/phase8_index.html
```

## Current Important Files

### Generated Data

Decimal source and golden files:

```text
model_lite/sr_core/generated/
model_lite/sr_core/generated/golden/
```

Vivado two's-complement hex files:

```text
model_lite/sr_core/generated_vivado_hex/
```

Conversion tool:

```text
model_lite/sr_core/tools/convert_generated_to_vivado_hex.py
```

### Vivado Project

Current Vivado project:

```text
model_lite/sr_core/vivado/sr_core_bram_pynqz2/sr_core_bram_pynqz2.xpr
```

Current streaming / image-level Vivado project:

```text
model_lite/sr_core/vivado/sr_core_streaming_pynqz2/sr_core_streaming_pynqz2.xpr
```

Existing BMG ROM IPs:

```text
conv1_weight_rom
conv3_weight_rom
conv1_m0_rom
conv1_m1_rom
conv3_m0_rom
conv3_m1_rom
```

Known ROM configuration:

| ROM | Depth | Width | Read Latency |
|---|---:|---:|---:|
| `conv1_weight_rom` | 72 | 8 | 1 clock |
| `conv3_weight_rom` | 32 | 8 | 1 clock |
| `conv1_m0_rom` | 8 | 32 | 1 clock |
| `conv1_m1_rom` | 8 | 64 | 1 clock |
| `conv3_m0_rom` | 4 | 32 | 1 clock |
| `conv3_m1_rom` | 4 | 64 | 1 clock |

## Phase8.4b Current Architecture

Phase8.4b implements:

```text
Vivado ROM IP
-> preload FSM
-> parameter register bank
-> verified sr_core_top datapath
-> output_uint8
```

Phase8.4b files:

```text
model_lite/sr_core/RTL_sys/phase8_4_rom_preload_wrapper/
  sr_core_top_rom_preload_wrapper.v
  tb_sr_core_top_rom_preload_wrapper.v
  tb_sr_core_top_rom_preload_wrapper_result.txt
  feature_mem0_dump.txt
  feature_mem1_dump.txt
  feature_mem2_dump.txt
```

Phase8.4b documentation:

```text
model_lite/sr_core/html/phase8_4b_rom_preload_wrapper.html
```

## Phase9.2 Current Architecture

Phase9.2 implements:

```text
Vivado parameter ROM prototype
-> preload FSM
-> parameter register bank
-> Conv1 block
-> Conv1 to Conv3 register slice
-> Conv3 block
-> conv3_feature_ram raw port
-> PixelShuffle
-> OutputStage
-> output_image_ram raw port
```

Phase9.2 intentionally does not instantiate the old `sr_core_top`.

Phase9.2 files:

```text
model_lite/sr_core/RTL_sys/phase9_streaming_architecture/
  sr_core_top_stream_ram_wrapper.v
  phase9_behavioral_ram_models.v
  tb_sr_core_top_stream_ram_wrapper.v
  tb_sr_core_top_stream_ram_wrapper_result.txt
  conv1_to_conv3_stream_dump.txt
  conv3_feature_ram_dump.txt
  output_image_ram_dump.txt
```

Phase9.2 Vivado project:

```text
model_lite/sr_core/vivado/sr_core_streaming_pynqz2/sr_core_streaming_pynqz2.xpr
model_lite/sr_core/vivado/sr_core_streaming_pynqz2/tcl/create_sr_core_streaming_pynqz2.tcl
```

New Phase9 RAM IP prototypes:

```text
conv3_feature_ram
  Simple Dual Port RAM
  width = 32
  depth = 64
  word = {c3, c2, c1, c0}

output_image_ram
  True Dual Port RAM
  width = 16
  depth = 128
  word = {right_uint8, left_uint8}
```

Phase9.2 documentation:

```text
model_lite/sr_core/html/phase9_2_reference_like_ram_architecture.html
model_lite/sr_core/html/phase9_2_vivado_ram_gui.html
```

## Phase9.3 to Phase9.5 Current Architecture

Phase9.3 reorganizes the hierarchy so Vivado schematic is easier to read:

```text
sr_nn_top
  -> sr_stream_mem_controller style control
  -> parameter preload controller
  -> parameter ROM IP
  -> Conv1 block
  -> Conv1 to Conv3 register slice
  -> Conv3 block
  -> conv3_feature_ram
  -> PixelShuffle
  -> output pack
  -> output_image_ram
```

Phase9.4 verifies the same hierarchy with real Vivado BMG ROM/RAM IP simulation wrappers.

Phase9.5 extends the test from 8x8 patch verification to a full 128x128 LR image:

```text
TB reads butterflyx2_Y.txt
-> TB converts uint8 to signed int8 by subtracting 128
-> sr_nn_top_img
-> parameter ROM IP
-> Conv1, IMG_W=128, IMG_H=128
-> Conv1 to Conv3 image register slice
-> Conv3
-> conv3_feature_ram_img, width=32, depth=16384
-> PixelShuffle x2
-> output_image_ram_img, width=16, depth=32768
-> TB reads output RAM
-> sr_output_uint8.txt
-> Python converts to PNG and computes PSNR
```

Phase9.5 files:

```text
model_lite/sr_core/RTL_sys/phase9_5_image_test/
  rtl/sr_nn_top_img.v
  rtl/sr_ctrl_img.v
  rtl/sr_c1c3_slice_img.v
  rtl/sr_out_pack_img.v
  sim/tb_sr_nn_top_img.v
  results/tb_sr_nn_top_img_result.txt

model_lite/sr_core/tools/test_img/sr_image_eval.py
model_lite/sr_core/pic/test_pic/result/
  sr_output_uint8.txt
  sr_output.png
  bilinear_x2.png
  software_golden_output.png
  image_eval_report.md
  image_eval_summary.txt
```

Vivado streaming project source snapshot:

```text
model_lite/sr_core/vivado/sr_core_streaming_pynqz2/src/
  rtl/
  tb/
  manifest/SOURCE_SNAPSHOT_MAP.txt
```

Module relationship map:

```text
model_lite/sr_core/RTL_sys/MODULE_RELATIONSHIP_MAP.txt
```

Snapshot rule:

```text
Vivado streaming project uses src/ as a project-local source snapshot.
RTL/ remains the golden verified source library.
RTL_sys/ remains the architecture development workspace.
If original RTL changes, refresh src/ and update SOURCE_SNAPSHOT_MAP.txt.
```

Phase9.5 documentation:

```text
model_lite/sr_core/html/phase9_5_image_inference_test.html
```

Important Phase9.5 lesson:

```text
If Vivado GUI has sr_core_streaming_pynqz2.xpr open, batch Tcl may open it read-only.
Close the GUI project before running run_phase9_5_image_sim.tcl.
Vivado generated logs, .jou files, .Xil, and accidental -p folders are disposable.
```

## Verification Philosophy

Every stage should be verified against runtime-verified golden data.

The standard PASS condition is:

```text
mismatch count = 0
max abs diff = 0
PASS
```

Debug order:

1. Check `tb_*_result.txt`.
2. Check mismatch print messages.
3. Compare intermediate dumps:
   - `feature_mem0_dump.txt` against `conv1_out_int8.mem`
   - `feature_mem1_dump.txt` against `conv3_out_int8.mem`
   - `feature_mem2_dump.txt` against `pixel_shuffle_out_int8.mem`
4. Only then inspect RTL timing or memory mapping.

## HTML Documentation Rules

All HTML documents should follow the existing index-style layout:

```html
<!doctype html>
<html lang="zh-Hant">
<head>
  <meta charset="utf-8">
  <title>...</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <main class="page">
    <nav class="quick-links">
      <span>相關目錄：</span>
      <a href="index.html">SR Core 首頁</a>
      <a href="rtl/index.html">RTL Modules</a>
      <a href="RTL_sys_index.html">RTL_sys</a>
      <a href="phase8_index.html">Phase8</a>
      <a href="tool_convert_generated_to_vivado_hex.html">Vivado Hex Tool</a>
    </nav>
    ...
  </main>
</body>
</html>
```

Important details:

- Always include `<meta charset="utf-8">`.
- Always use `<main class="page">`.
- Use `style.css`.
- Put related links near the top.
- Update `index.html` for major documents.
- Update `RTL_sys_index.html` for architecture work.
- Update `phase8_index.html` for Phase8 subphases.

Avoid PowerShell full-file rewrites for Chinese HTML.

After editing HTML, check for mojibake tokens:

```text
U+FFFD replacement character
U+5697
U+929D
U+875D
U+64A0
U+95AC
```

## Verilog Coding Rules

Use Verilog `.v`, not SystemVerilog.

Avoid:

```text
logic
always_comb
always_ff
interface
typedef
enum
struct
packed/unpacked array ports
overly abstract generate frameworks
```

Prefer:

```text
readable datapath
explicit wire/reg
clear memory mapping
clear FSM state names
beginner-readable comments
result txt based verification
```

## Important Lessons Learned

### 1. Keep verified RTL frozen

The biggest engineering protection is the separation:

```text
RTL      -> verified module library
RTL_sys  -> architecture refactor workspace
```

This prevents future refactors from breaking already verified modules.

### 2. Behavioral memory and Vivado ROM are not the same

Behavioral register memory can appear same-cycle.

Vivado BMG ROM is synchronous:

```text
cycle N:   address / enable
cycle N+1: data valid
```

That is why Phase8.4b uses preload FSM and parameter register banks.

### 3. Documentation must record why

For this project, HTML is not only a report. It is the architecture knowledge base.

Every new phase should explain design reasoning, alternatives, verification files, problems encountered, result, and next step.

## Recommended Next Step

The likely next phase is:

```text
Phase10 / Deployment Preparation
```

Recommended next goals:

```text
1. Clean disposable Vivado runtime files:
   vivado.jou, vivado.log, vivado_*.backup.*, .Xil, accidental -p folders.

2. Inspect sr_core_streaming_pynqz2 schematic:
   Confirm parameter ROM IP, Conv blocks, RAM IP, PixelShuffle, and output pack
   appear at the intended reference-like hierarchy level.

3. Decide next deployment boundary:
   - Keep TB-driven input for now, or
   - plan an input RAM / AXI loading interface.

4. Do not modify RTL/ golden modules.
```

Keep:

```text
RTL/ untouched
input still TB-driven unless explicitly starting AXI/DMA work
no PS-PL integration until the PL-side RAM/IP architecture is stable
```

Phase9.1 analysis is already documented here:

```text
model_lite/sr_core/html/phase9_1_conv1_conv3_streaming_analysis.html
```

Phase9.5 is now complete and PASS. Future work should use the Phase9.5 image-level
flow as the current PL-side correctness checkpoint instead of returning to only
the 8x8 patch flow.

## Codex Skill

Project-local skill files:

```text
model_lite/sr_core/skill/sr-accelerator-rtl-flow/SKILL.md
model_lite/sr_core/skill/vivado-ip-gui-doc-flow/SKILL.md
model_lite/sr_core/skill/sr-token-efficient-workflow/SKILL.md
model_lite/sr_core/skill/sr-core-chat-handoff-flow/SKILL.md
```

Use `sr-accelerator-rtl-flow` as the Codex working rulebook for future SR accelerator RTL tasks.

Use `vivado-ip-gui-doc-flow` when Codex needs to create, inspect, or modify Vivado IP.
This second skill is important because every Vivado IP action should leave enough GUI documentation
for a future manual rebuild inside Vivado.

Use `sr-token-efficient-workflow` to decide how much context to read and which verification level to run.

Use `sr-core-chat-handoff-flow` before ending a long chat or starting a new one.
