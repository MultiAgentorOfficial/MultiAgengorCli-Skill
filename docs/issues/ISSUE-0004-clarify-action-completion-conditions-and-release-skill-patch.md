---
id: ISSUE-0004
title: "Clarify action completion conditions and release Skill patch"
status: in-progress
priority: high
created: 2026-10-10
updated: 2026-10-10
closed:
sources: ["User test report and correction request, 2026-10-10"]
related_adrs: []
depends_on: []
---

# ISSUE-0004: Clarify action completion conditions and release Skill patch

## Problem

Skill does not explicitly forbid waitFor on navigation, leading to invalid back requests.

## Desired outcome

Publish Skill 2.0.1 from its maintenance source with explicit restrictions and valid navigation/click examples; synchronize installed Skill.

## Acceptance criteria

- [x] Maintenance-source Skill explicitly limits waitFor to click/scroll and verifies navigation observations.
- [x] Correct local request examples cover goto/back/reload and conditioned click/scroll.
- [ ] Skill validation passes; 2.0.1 is published and installed via its updater.

## Out of scope

Not defined.

## Decisions

No decisions recorded.

## Implementation notes

No implementation has started.

## Verification

Skill 2.0.1 quick_validate passed with explicit UTF-8; current-CLI discovery regression passed (1 passed, legacy-only case skipped). Five JSON envelope examples are consistent with the maintained CLI action contract. Narrow source review found no blocking findings. Publication and installed updater verification pending.

## Activity log

### 2026-10-10 — Created

Issue created from the supplied project input.

### 2026-10-10 — Status changed from proposed to ready.

### 2026-10-10 — Status changed from ready to in-progress.

## Completion summary

Not completed.
