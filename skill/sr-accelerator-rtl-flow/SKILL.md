---
name: sr-accelerator-rtl-flow
description: Use this skill when working on the model_lite/sr_core FPGA Super Resolution accelerator RTL project, including Verilog RTL verification, RTL_sys architecture refactors, Vivado ROM/BRAM integration, golden .mem comparison, result txt generation, and project HTML documentation with index-style navigation.
---

# SR Accelerator RTL Flow

This skill is for `model_lite/sr_core`, a runtime-verified quantized Super Resolution accelerator RTL project.

Use it whenever the user asks to continue SR Core RTL, RTL_sys, Phase8+, Vivado ROM/BRAM work, testbench verification, golden compare, or HTML project documentation.

For Vivado IP creation, BMG ROM/RAM configuration, or GUI reconstruction notes, also use:

```text
model_lite/sr_core/skill/vivado-ip-gui-doc-flow/SKILL.md
```

## Core Rule

`model_lite/sr_core/RTL/` is the Golden Verified RTL Module Library.

Do not modify verified RTL modules there unless the user explicitly asks to change the golden module library.

Architecture refactor work belongs in:

```text
model_lite/sr_core/RTL_sys/
```

Documentation belongs in:

```text
model_lite/sr_core/html/
```

## Current Project Meaning

The project implements:

```text
input_int8_for_core
-> Conv1 3x3, Cin=1, Cout=8
-> requant, fused ReLU behavior
-> Conv3 1x1, Cin=8, Cout=4
-> requant
-> PixelShuffle x2
-> output stage, int8 to uint8
```

Golden data comes from runtime-verified TFLite / NumPy reconstruction.

The PASS standard is strict bit-exact comparison:

```text
mismatch count = 0
max abs diff = 0
PASS
```

## Verilog Style

Use Verilog `.v`, not SystemVerilog.

Avoid:

- `logic`
- `always_comb`
- `always_ff`
- `interface`
- `typedef`
- `enum`
- `struct`
- packed/unpacked array ports
- overly abstract generate frameworks

Prefer:

- readable datapath
- explicit `wire` / `reg`
- clear counters and FSM states
- clear memory mapping
- beginner-readable testbench flow

## RTL Verification Pattern

For every RTL or RTL_sys phase, produce these artifacts when relevant:

```text
module_name.v
tb_module_name.v
tb_module_name_result.txt
optional feature_mem*_dump.txt
html/phaseX_description.html
```

The testbench should:

1. Read input/golden files.
2. Drive the DUT.
3. Compare against golden.
4. Print mismatch details.
5. Write a result txt in the same folder as the testbench.

For decimal `.mem` files, use:

```verilog
$fopen
$fscanf
```

Do not use `$readmemh` for signed decimal text.

For Vivado hex or `.memh` files, `$readmemh` is appropriate.

## Generated Data Rules

Source decimal files:

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

Do not regenerate golden files unless the user explicitly asks.

## Vivado ROM / BRAM Rules

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

Known timing:

```text
Vivado BMG ROM read latency = 1 clock
```

Do not assume same-cycle data. Use:

```text
SEND_ADDR
-> WAIT_DATA
-> CAPTURE_DATA
-> NEXT_ADDR
```

For correctness-first integration, preload ROM contents into parameter register banks before starting the verified core.

If Codex creates or modifies Vivado IP, the equivalent GUI flow must be documented in HTML.
Do not leave only Tcl commands; record the GUI path, option values, reason for each value, and matching Tcl.

## HTML Documentation Rules

All project HTML should follow the existing index-style layout:

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

Important:

- Always include `<meta charset="utf-8">`.
- Always use `<main class="page">`.
- Use the shared stylesheet: `style.css`.
- Put related links near the top.
- Update `html/index.html` when adding a major document.
- Update `html/RTL_sys_index.html` when adding RTL_sys architecture work.
- Update `html/phase8_index.html` for Phase8 subphases.

Each phase HTML should explain:

1. Phase goal.
2. Existing problem.
3. Why the old architecture is not enough.
4. New design idea.
5. RTL changes.
6. Verification files.
7. Verification flow.
8. PASS condition.
9. Problems encountered.
10. Final conclusion.
11. Next phase.

Do not only record results. Record why.

## Chinese HTML Encoding Safety

Avoid PowerShell `Get-Content | Set-Content` or full-file PowerShell rewrites for Chinese HTML.

Preferred:

- `apply_patch` for manual edits.
- Python UTF-8 read/write only when mechanical edits are needed.

After editing HTML, check these mojibake tokens:

```text
U+FFFD replacement character
U+5697
U+929D
U+875D
U+64A0
U+95AC
```

If any appear, treat the HTML as damaged.

## Handoff Discipline

Before ending a major phase, update:

```text
model_lite/sr_core/handoff/HANDOFF.md
```

The handoff should include:

- latest PASS phase
- changed files
- verification command/result
- next recommended phase
- any hazards or assumptions

## Current Phase Boundary

As of the latest handoff, Phase8.4b is PASS:

```text
Vivado ROM IP
-> preload FSM
-> parameter register bank
-> verified RTL pipeline
-> output_uint8.mem

mismatch count = 0
max abs diff = 0
PASS
```

Next likely work:

```text
Phase9 Streaming Architecture Refactor
```
