---
id: ISSUE-0006
title: "Consolidate MA Skill routing and execution references"
status: in-progress
priority: high
created: 2026-10-29
updated: 2026-10-29
closed:
sources: ["2026-10-29 user approved implementation of MA Skill and factory refactoring plan"]
related_adrs: []
depends_on: []
---

# ISSUE-0006: Consolidate MA Skill routing and execution references

## Problem

Repeated lifecycle guidance and stale protocol advice obscure authoritative execution rules.

## Desired outcome

Keep one automatic entry and conditional references with trace-based evaluation fixtures.

## Acceptance criteria

- [x] One automatic entry and conditional authoritative references; stale protocol advice removed.
- [x] Fixed-receipt cases and trace evaluator cover reuse/create/login/lost reply/unknown effect/close.
- [x] Skill validation, script tests, links and fixed-base review pass; fresh-Agent evidence separately recorded.

- [ ] Six controlled branches have authentic fresh-Agent tool/decision traces with reviewed provenance.

## Out of scope

Runtime/service/API changes, global/dist installation, publication and account execution.

## Implementation notes

Source Skill version 2.1.1 retains one automatic entry. Guided workflow owns task reuse/resource decisions; supervised execution owns requests, lost/unknown responses, closure and report; efficient observation owns supplementation/cached reads/full/unchanged/delta references. Authentication, memory and visual verification are conditional. Retired worker-execution.md remains an explicit redirect because update checks depend on it. Current schemas come from pinned describe; obsolete parameter table and duplicated lifecycle recipes were removed.

Six controlled fixture cases and a provenance-aware trace checker are present. Unit examples test the checker, not model behavior. Negative examples carry valid sourceRef values and assert the specific count/order/forbidden violation, so missing provenance cannot mask a broken behavioral assertion.

## Verification

2026-10-29: quick_validate.py reports Skill is valid; all local Markdown file targets under the Skill exist; git diff --check passes. Bundled Node 22.23.4 with actual official npm CLI 0.4.3 supplied through MULTIAGENTOR_CONTRACT_TEST_CLI: 5 tests, 4 pass, 0 fail, 1 skip (actual legacy launcher absent). Includes actual candidate contract discovery/corruption rejection, pinned request helper and synthetic trace-checker tests. Final negative-assertion strengthening reran both trace tests successfully.

Fixed-base read-only review: git diff 7bcd6ad3d3db18cd96f4dc87908eecfbdd778b50 -- plus new eval/test files. No new commits. Conditional routes/ownership, request uncertainty, permission/budget preservation, terminal verification and provenance limits reviewed; no unresolved source findings. No dist/global change. Factory locks the final Skill bytes by digest fdc58f6efb3ee3eb2ce6bbd28d65788b13737b0b4adb187c37b2ac4dcb9fc07e as working-tree candidate, not a release commit.

Normalized LF UTF-8 source bytes before → after: entry 4456 → 3200; execution map 5250 → 1634; guided 17257 → 13874; supervised 9044 → 7340; observation 4246 → 5310 (now owns moved guidance). These are file sizes, not actual loaded-document/Token traces. No authentic fresh-Agent runs or before/after Token measurements were performed. Controlled acceptance procedure records these explicit gaps; Issue remains in-progress until provenance-reviewed traces exist.

## Activity log

### 2026-10-29 — Created

Issue created from the supplied project input.

### 2026-10-29 — Status changed from proposed to ready.

### 2026-10-29 — Status changed from ready to in-progress.

## Completion summary

Source consolidation and checker implementation are verified. Fresh-Agent behavioral acceptance remains outstanding; factory ISSUE-0018 also tracks real runtime acceptance. No account action, publication, commit or push.

## Decisions

Base 7bcd6ad3d3db18cd96f4dc87908eecfbdd778b50; clean at start. Reuse Skill entry/reference/script boundaries. Guided workflow owns task/resource decisions; supervised execution owns local protocol/close; efficient observation owns supplementation. No runtime API or global/dist change. Trace evaluator consumes externally recorded JSONL decisions and fixed receipts; it does not execute or simulate an Agent. Fresh-Agent traces and real-site runs remain separate evidence.

## Trace evaluation design

Evaluation-only owner evals/evaluate-trace.mjs exports evaluateTrace(caseDefinition, events) -> {passed, violations, sourceLinked, agentBehaviorVerified:false}. It checks ordered required events, forbidden events and bounded counts against controlled receipts in trace-cases.json. CLI --case/--trace accepts normalized redacted JSONL with sourceRef pointers. Tests use literal synthetic traces to verify the checker, not Agent compliance. No model/network/runtime executor or dependency is added; recorded fresh-Agent provenance remains subject to human review.

## 2026-10-29 — Publication authorization

User explicitly requested commit, push and publication after the source rewrite report disclosed the missing real-X/fresh-Agent acceptance. Publish Skill2.1.1 source and its exact Git-blob ZIP through the existing GitHub distribution; no runtime/npm change or global installation. Schema validation passed; actual npm CLI0.4.3 test run:5 tests,4 passed,0 failed,1 skipped for the absent legacy fixture. Publication does not close the remaining authentic trace criterion.
