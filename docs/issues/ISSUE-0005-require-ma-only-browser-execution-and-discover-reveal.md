---
id: ISSUE-0005
title: "Require MA-only browser execution and discover reveal"
status: done
priority: high
created: 2026-10-28
updated: 2026-10-28
closed: 2026-10-28
related_adrs: []
depends_on: []
---

# ISSUE-0005: Require MA-only browser execution and discover reveal

## Problem

MA runs must not mix independent automation tools and need a discoverable pre-click positioning recovery procedure.

## Desired outcome

Official MA Skill requires exclusive MA CLI browser execution and consumes reveal observations without redundant actions.

## Acceptance criteria

- [x] Official Skill requires all MA browser observations/actions/login assistance/recovery through MA CLI only, explicitly excluding other automation drivers.
- [x] Shell/file helpers remain permitted for MA invocation and evidence; MA internal browser implementation is distinguished from external takeover.
- [x] Reveal is discovered when required, used only for pre-click observation/recovery, and its latest observation replaces old refs.
- [x] Skill validation, candidate discovery tests and fixed-base review pass; no installed/global copy or release artifacts replaced.

## Out of scope

No account execution, installation, release, staging, commits or changes to unrelated user work.

## Decisions

Existing skills/multiagentor/SKILL.md owns shared execution constraints; references/supervised-execution.md owns conditional reveal procedure. No scripts/runtime behavior required for a policy-only edit; test validation checks package correctness and actual candidate discovery, not wording regexes. Isolation is an Agent execution rule with trace-based acceptance, not a false claim of host enforcement. Review base 8cc634b76b19f3103c9501d73ec0d561719ebbbc. Source-only changes; no dist/archive/global-install regeneration.

## Implementation notes

Source Skill candidate2.0.2 adds shared MA-only browser execution rule, permitted shell/evidence boundary, explicit forbidden drivers, trace invalidation and truthful host-enforcement limit. Conditional reveal discovery/recovery lives in supervised-execution reference; ordinary click keeps its existing automatic scrolling. No new scripts, generated distribution or installed Skill replacement.

## Verification

2026-10-28: `python -X utf8 C:/Users/frank/.codex/skills/.system/skill-creator/scripts/quick_validate.py skills/multiagentor` passed. `MULTIAGENTOR_CONTRACT_TEST_CLI=<local-built-CLI> Node22.23.3 --test tests/discovery.test.mjs`:1 passed,1 skipped because no legacy test binary supplied; actual candidate describe discovery and damaged-contract rejection passed. Initial validator invocation used system GBK default; rerun with explicit UTF-8 succeeded without changing Skill bytes. git diff --check passed. Fixed-base read-only review: git diff8cc634b76b19f3103c9501d73ec0d561719ebbbc -- skills/multiagentor plus new Issue; no actionable source findings. Narrow instruction changes validated without wording-matching pseudo-behavior tests. Runtime isolation remains an instruction/tracing boundary, not enforcement by CLI. No installed/global or factory-locked Skill was replaced; future live acceptance must use the synchronized candidate.

## Activity log

### 2026-10-28 — Created

Issue created from the supplied project input.

### 2026-10-28 — Status changed from proposed to ready.

### 2026-10-28 — Status changed from ready to in-progress.

### 2026-10-28 — Status changed from in-progress to done.

## Completion summary

Official Skill2.0.2 source requires MA-only browser execution and conditional reveal recovery; validation and candidate discovery passed, no installed or release copies replaced.
