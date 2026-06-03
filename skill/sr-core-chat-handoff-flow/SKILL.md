---
name: sr-core-chat-handoff-flow
description: Use this skill when preparing model_lite/sr_core for a new chat, writing compact handoff notes, reducing context, or creating a concise continuation prompt.
---

# SR Core Chat Handoff Flow

Use this skill when ending a long chat or preparing to continue `model_lite/sr_core` in a new chat.

## Handoff Principle

The handoff should be an index, not a full article.

Detailed explanations live in:

```text
html/
```

Current module/file relationships live in:

```text
RTL_sys/MODULE_RELATIONSHIP_MAP.txt
vivado/sr_core_streaming_pynqz2/src/manifest/SOURCE_SNAPSHOT_MAP.txt
```

The new chat should start from:

```text
handoff/HANDOFF.md
```

## What Handoff Should Include

Keep `handoff/HANDOFF.md` focused on:

1. Current main goal.
2. Latest PASS checkpoint.
3. Files that must not be touched.
4. Current Vivado project.
5. Current source snapshot rule.
6. Verification levels.
7. Common commands.
8. Next recommended task.

Avoid copying old prompts or long phase explanations.

## New Chat Startup Prompt

Use this prompt:

```text
I am continuing model_lite/sr_core.

Please first read:
- handoff/HANDOFF.md
- RTL_sys/MODULE_RELATIONSHIP_MAP.txt
- vivado/sr_core_streaming_pynqz2/src/manifest/SOURCE_SNAPSHOT_MAP.txt

Use project skills:
- sr-accelerator-rtl-flow
- sr-token-efficient-workflow
- sr-core-chat-handoff-flow

Current task:
<write the next task here>

Verification level:
Level <0-4>

Important:
Do not modify RTL/ golden verified modules unless I explicitly ask.
```

If the task touches Vivado IP GUI documentation, also use:

```text
skill/vivado-ip-gui-doc-flow/SKILL.md
```

## Before Ending A Chat

1. Run only the verification level needed for the latest change.
2. Update `handoff/HANDOFF.md` with latest PASS/FAIL and next step.
3. Update `MODULE_RELATIONSHIP_MAP.txt` if hierarchy or file locations changed.
4. Update `SOURCE_SNAPSHOT_MAP.txt` if Vivado `src/` snapshot changed.
5. Commit/push if requested.
6. Tell the user exactly which files the next chat should read.

## Compact Handoff Block

End with:

```text
Latest commit:
<hash / not committed>

Latest PASS:
<verification level and result>

Next task:
<one sentence>

New chat should read:
1. handoff/HANDOFF.md
2. RTL_sys/MODULE_RELATIONSHIP_MAP.txt
3. vivado/sr_core_streaming_pynqz2/src/manifest/SOURCE_SNAPSHOT_MAP.txt
```
