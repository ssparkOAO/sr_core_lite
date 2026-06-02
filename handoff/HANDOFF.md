# SR Core Handoff

This handoff is for the `model_lite/sr_core` FPGA-based Super Resolution accelerator RTL project.

The project has moved from module-level RTL verification into system architecture refactor work. Treat this file as the first document to read before continuing the project.

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

Latest end-to-end Phase8.4b result:

```text
preload_done asserted
mismatch count = 0
max abs diff   = 0
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
Phase9 Streaming Architecture Refactor
```

Recommended Phase9 goal:

```text
Reduce stage-memory-oriented verification top toward a clearer streaming architecture,
while preserving the current PASS behavior and keeping RTL/ untouched.
```

Before starting Phase9, create:

```text
model_lite/sr_core/RTL_sys/phase9_streaming_architecture/
model_lite/sr_core/html/phase9_streaming_architecture.html
```

Start with architecture analysis first, not immediate RTL rewrite.

## Codex Skill

Project-local skill files:

```text
model_lite/sr_core/skill/sr-accelerator-rtl-flow/SKILL.md
model_lite/sr_core/skill/vivado-ip-gui-doc-flow/SKILL.md
```

Use `sr-accelerator-rtl-flow` as the Codex working rulebook for future SR accelerator RTL tasks.

Use `vivado-ip-gui-doc-flow` when Codex needs to create, inspect, or modify Vivado IP.
This second skill is important because every Vivado IP action should leave enough GUI documentation
for a future manual rebuild inside Vivado.
