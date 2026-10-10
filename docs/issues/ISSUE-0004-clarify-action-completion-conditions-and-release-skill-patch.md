---
id: ISSUE-0004
title: "Clarify action completion conditions and release Skill patch"
status: done
priority: high
created: 2026-10-10
updated: 2026-10-10
closed: 2026-10-10
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
- [x] Skill validation passes; 2.0.1 is published and installed via its updater.

## Out of scope

CLI source changes (tracked separately), external website writes and unrelated workflow changes.

## Decisions

Preserve CLI 0.4.0+ compatibility; waitFor is limited to click/scroll while navigation uses default completion and returned-page verification.

## Implementation notes

Added an entrypoint rule and five local request examples in supervised-execution.md, and bumped metadata.version to 2.0.1. Modified the maintenance source, published it, then used the installed updater; no direct installed-file edits.

## Verification

Skill 2.0.1 quick_validate passed with explicit UTF-8; current-CLI discovery regression passed (1 passed, legacy-only case skipped). Five JSON envelope examples are consistent with the maintained CLI action contract. Narrow source review found no blocking findings. Published source 750dbc4 and annotated v2.0.1 on origin/main. GitHub release ZIP independently downloaded and SHA-256 matched d2a7ce1c1c0d62547893f196c5e71fc556bf55d92ed99b16f7e6a5d02a4a7077. Installed updater with -Ref v2.0.1 reported currentVersion=2.0.0, latestVersion=2.0.1, updated=true, integrityOk=true and restartRequired=true. New chats load the installed instructions. CLI changes tracked separately in CLI ISSUE-0050.

## Activity log

### 2026-10-10 — Created

Issue created from the supplied project input.

### 2026-10-10 — Status changed from proposed to ready.

### 2026-10-10 — Status changed from ready to in-progress.

### 2026-10-10 — Status changed from in-progress to done.

## Completion summary

Published Skill 2.0.1 with explicit waitFor limits, correct local request examples and navigation result verification; synchronized the installed Skill via the official updater.
