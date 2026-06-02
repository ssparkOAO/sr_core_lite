---
name: vivado-ip-gui-doc-flow
description: Use this skill when creating, inspecting, or modifying Vivado IP for the model_lite/sr_core project, especially Block Memory Generator ROM/RAM IP. It requires using the existing Vivado project when available, recording Tcl actions, documenting equivalent Vivado GUI steps in HTML, preserving UTF-8 documentation, and verifying generated IP behavior before wrapper integration.
---

# Vivado IP GUI Documentation Flow

This skill is for Vivado IP work in the SR accelerator project.

Use it when the user asks Codex to:

- open or use Vivado
- create ROM/RAM/BRAM IP
- inspect BMG IP configuration
- update IP parameters
- generate `.xci`, `.coe`, `.mif`, or IP simulation files
- document GUI steps for future manual rebuild
- update `phase8_3_vivado_bram_gui.html` or similar Vivado GUI notes

## Project Boundary

Default Vivado project:

```text
model_lite/sr_core/vivado/sr_core_bram_pynqz2/sr_core_bram_pynqz2.xpr
```

Do not create a new Vivado project unless the user explicitly asks.

Do not recreate existing IP unless the user explicitly asks.

Existing parameter ROM IP names:

```text
conv1_weight_rom
conv3_weight_rom
conv1_m0_rom
conv1_m1_rom
conv3_m0_rom
conv3_m1_rom
```

## Naming Rule

Use names that match the memory behavior:

```text
*_rom  -> read-only fixed parameters
*_ram  -> writable memory
```

For instances, use:

```text
u_conv1_weight_rom
u_conv3_weight_rom
u_conv1_m0_rom
u_conv1_m1_rom
u_conv3_m0_rom
u_conv3_m1_rom
```

Do not call a read-only ROM instance `*_bram` when the user expects ROM/RAM naming clarity.

## BMG Meaning

`BMG` means:

```text
Block Memory Generator
```

It is the Xilinx / Vivado IP used to generate ROM/RAM/BRAM style memories.

## Required Workflow

For every Vivado IP task, follow this order:

1. Inspect current project/IP first.
2. Record current IP settings before changing anything.
3. If creating or modifying IP, do it through Tcl or Vivado project commands.
4. Record the equivalent GUI path and option values in HTML.
5. Generate or confirm `.xci` / simulation wrapper / init file.
6. Verify behavior with a testbench or configuration report.
7. Update relevant index HTML.

Do not jump directly into wrapper integration before confirming IP configuration and timing.

## GUI Documentation Requirement

Every IP phase should have an HTML document explaining how to rebuild the IP manually in Vivado GUI.

The document should use the existing project HTML style:

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

Do not forget:

- `<meta charset="utf-8">`
- `<main class="page">`
- `quick-links`
- link back to `RTL_sys_index.html`
- link back to the relevant phase index

## GUI Step Format

Each GUI step should record:

```text
Step number
GUI path
Option name
Actual selected value
Why this value was chosen
Equivalent Tcl
Notes / pitfalls
```

Example table columns:

```text
GUI Option | Selected Value | Why | Equivalent Tcl
```

Example:

```text
GUI:
IP Catalog -> Block Memory Generator -> Customize IP

Option:
Memory Type = Single Port ROM

Why:
Weights and M0/M1 are fixed inference parameters.

Tcl:
set_property CONFIG.Memory_Type {Single_Port_ROM} [get_ips conv1_weight_rom]
```

## BMG ROM Option Checklist

For BMG ROM IP, always document these fields:

```text
IP name
Memory Type
Port Type
Read Width
Read Depth
Address Width
Enable Signal
Load Init File
COE File
Output Register
Read Latency
Reset Port
Generated files
```

For the current project, the preferred prototype configuration is:

```text
Memory Type = Single Port ROM
Enable_A = Use_ENA_Pin
Load_Init_File = true
Output Register = disabled
Read Latency = 1 clock
```

## COE / Hex Rule

Vivado ROM init files should come from:

```text
model_lite/sr_core/generated_vivado_hex/
```

The original decimal golden/source files remain in:

```text
model_lite/sr_core/generated/
```

Use the conversion tool if files need to be regenerated:

```text
model_lite/sr_core/tools/convert_generated_to_vivado_hex.py
```

Do not manually edit generated hex files unless the user explicitly requests it.

## Configuration Report Before Integration

Before connecting IP into a wrapper, produce or update a configuration report HTML.

It should include:

```text
ROM Type
Data Width
Address Width
Depth
Read Latency
Enable Signal
Output Register
Init File
```

This is why Phase8.4a existed: ROM latency must be understood before wrapper integration.

## Verification Requirement

Creating IP is not enough.

A phase is not complete until one of these is true:

1. IP configuration report is complete, if the phase is analysis-only.
2. IP readback self-check PASS.
3. IP-backed wrapper end-to-end PASS.

PASS format:

```text
mismatch count = 0
max abs diff = 0
PASS
```

When possible, write a result txt in the same folder as the testbench.

## Vivado Simulation Notes

Vivado-generated BMG simulation wrappers live under:

```text
model_lite/sr_core/vivado/sr_core_bram_pynqz2/sr_core_bram_pynqz2.gen/sources_1/ip/*/sim/*.v
```

The shared BMG simulation model may live under:

```text
.../simulation/blk_mem_gen_v8_4.v
```

The simulator may print:

```text
Block Memory Generator module loading initial data...
... is using a behavioral model for simulation ...
```

That is normal for Xilinx IP simulation. It does not mean the project used a hand-written local ROM.

## HTML Encoding Safety

Avoid PowerShell full-file rewrites for Chinese HTML.

Preferred:

- `apply_patch` for manual edits
- Python UTF-8 read/write for mechanical edits

After editing HTML, check for:

```text
U+FFFD replacement character
U+5697
U+929D
U+875D
U+64A0
U+95AC
```

If any appear, treat the HTML as damaged.

## Index Update Rule

After adding a Vivado IP document, update the relevant indexes:

```text
model_lite/sr_core/html/index.html
model_lite/sr_core/html/RTL_sys_index.html
model_lite/sr_core/html/phase8_index.html
```

Use index-style links near the top of the page.

## Current Reference Documents

Current Vivado IP reference documents:

```text
model_lite/sr_core/html/phase8_3_vivado_bram.html
model_lite/sr_core/html/phase8_3_vivado_bram_gui.html
model_lite/sr_core/html/phase8_4_rom_backed_wrapper.html
model_lite/sr_core/html/phase8_4a_rom_timing_analysis.html
model_lite/sr_core/html/phase8_4b_rom_preload_wrapper.html
```

Use these as style and content references for future Vivado IP work.

