---
name: sr-token-efficient-workflow
description: Use this skill when continuing model_lite/sr_core with minimum token and runtime cost, deciding what context to read, which verification level to run, and when to avoid expensive Vivado runs.
---

# SR Token-Efficient Workflow

Use this skill to keep large `model_lite/sr_core` tasks focused and cheap.

## Core Rule

Do not reload the full Phase1 to Phase9 history for every task.

Start from these index files:

```text
handoff/HANDOFF.md
RTL_sys/MODULE_RELATIONSHIP_MAP.txt
vivado/sr_core_streaming_pynqz2/src/manifest/SOURCE_SNAPSHOT_MAP.txt
vivado/sr_core_streaming_pynqz2/README.txt
```

Then read only the specific phase HTML, RTL, TB, Tcl, or Python file related to the current task.

## Context Reading Order

1. Read `handoff/HANDOFF.md`.
2. Read `RTL_sys/MODULE_RELATIONSHIP_MAP.txt` for hierarchy and file locations.
3. Read `SOURCE_SNAPSHOT_MAP.txt` only when Vivado streaming source membership matters.
4. Read the specific files being edited.

Avoid scanning all of `RTL/`, all of `RTL_sys/`, or every HTML document unless the task truly requires it.

## Verification Levels

Use the smallest verification level that proves the change:

```text
Level 0: File / documentation check only
  Use for HTML, handoff, skill, README, and manifest-only edits.

Level 1: Python / text utility check
  Use for generated data tools, image evaluation, manifest checks, and encoding checks.

Level 2: Small RTL testbench
  Use for one module or one local wrapper.

Level 3: Phase9.5 image Vivado simulation
  Use when touching sr_nn_top_img, sr_ctrl_img, RAM/IP wiring, Tcl source membership,
  or image-level TB flow.

Level 4: Vivado synthesis / schematic / timing inspection
  Use when hierarchy, IP integration, or implementation readiness is the goal.
```

State the verification level used in the final response.

## Vivado Cost Rule

Vivado is expensive. Run it only when the task affects:

- Vivado `.xpr`
- Vivado `.xci`
- Tcl simulation scripts
- `vivado/sr_core_streaming_pynqz2/src/rtl/`
- `vivado/sr_core_streaming_pynqz2/src/tb/`
- RAM/ROM IP wiring
- top-level controller or hierarchy

Do not run Vivado for HTML, handoff, skill, README, or Python-only metric changes unless those changes affect hardware output.

## Snapshot Rule

The streaming Vivado project uses:

```text
vivado/sr_core_streaming_pynqz2/src/
```

This is a Vivado project snapshot, not the golden source library.

Golden verified modules remain in:

```text
RTL/
```

Architecture work remains in:

```text
RTL_sys/
```

If original RTL or RTL_sys files change and the streaming Vivado project should use them, refresh the snapshot and update:

```text
vivado/sr_core_streaming_pynqz2/src/manifest/SOURCE_SNAPSHOT_MAP.txt
RTL_sys/MODULE_RELATIONSHIP_MAP.txt
```

## New Chat Prompt

Use this instead of pasting the full project history:

```text
This is model_lite/sr_core.
Please read:
1. handoff/HANDOFF.md
2. RTL_sys/MODULE_RELATIONSHIP_MAP.txt
3. vivado/sr_core_streaming_pynqz2/src/manifest/SOURCE_SNAPSHOT_MAP.txt if Vivado source membership matters.

Current task:
<one sentence>

Allowed files:
<paths>

Verification level:
Level <0-4>

Important:
Do not modify RTL/ golden modules unless explicitly requested.
```

## Final Response Rule

For large tasks, report:

- what changed
- where it changed
- verification level used
- PASS/FAIL result
- commit/push status if Git was requested
