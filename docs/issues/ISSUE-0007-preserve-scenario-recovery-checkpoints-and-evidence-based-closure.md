---
id: ISSUE-0007
title: "Preserve scenario recovery checkpoints and evidence-based closure"
status: done
priority: high
created: 2026-10-30
updated: 2026-10-30
closed: 2026-10-30
related_adrs: []
depends_on: []
---

# ISSUE-0007: Preserve scenario recovery checkpoints and evidence-based closure

## Problem

Forensic evidence for two x-style-warmup 1.6.3 Runs shows generated helpers omitted recovery counters and step outcomes; the supervisor then hard-coded failed closure without documenting reconciliation or a mandatory stop condition.

## Desired outcome

Require scenario-complete helper preparation, immediate recovery records, evidence reconciliation and scenario-grounded terminal decisions without altering historical Runs.

## Acceptance criteria

- [x] Before business actions, the supervisor checks its persistence mechanism against the fixed scenario, including recovery increments and settled step records; no new runtime API or scenario-specific engine.
- [x] Recoverable local faults preserve original shared budgets and persist the attempt before recovery; initialization at zero is not evidence of subsequent accounting.
- [x] Missing records trigger evidence reconciliation without fabricated history or replay; continuation depends on provable critical state and the scenario's global gates.
- [x] Early close records the applicable scenario stop condition and evidence; an incomplete report alone is not a hard-coded failure condition, while proven protocol violations still fail as required.
- [x] Skill schema, local links, existing script tests and fixed-base review pass; live-Agent/account acceptance limitations are explicit.

## Out of scope

CLI/service/API changes, executable scenario engines, changes to the other machine's temporary helper or historical Run files, global installation, factory locks, release, Git mutations and account runs.

## Decisions

Reuse the existing Skill entry/reference boundary at base 4d3db01e5a20a6bcbff0b5fea001cfde22221b05. supervised-execution.md owns generic persistence/recovery/close decisions; the fixed scenario retains field names, retry limits, success and stop rules. SKILL.md routes the mandatory pre-action preparation there. task-memory.md retains CAS ownership. No new executable module, dependency or public API.

This is an instruction-only correction: no automated assertion of prose can prove Agent behavior. Use the existing Node script suite, Skill validator and link checks, and add realistic evaluation prompts for helper preparation, recoverable faults and unrecoverable critical state. Keep real Agent/30-minute acceptance separate.

Evidence: user-supplied 2026-10-30 forensic report and JSON appendix for Runs 422f4183-b6da-4329-b48d-198f2946ab9e and af572f7b-a041-42d9-bb52-c2d6fec7c54c. Reported helper omissions and fixed failed finalizer are the correction target; no independent access to those original files is claimed.

## Implementation notes

Source Skill candidate 2.1.2 adds mandatory persistence preparation and local-fixture checks for generated helpers; immediate recovery/step records; source-linked reconciliation with original budgets; per-Run evidence-based closure and retained non-secret close envelopes. Added four evaluation prompts. The remote temporary ma.mjs/finalize.mjs were not available and were not modified.

## Verification

2026-10-30: quick_validate.py skills/multiagentor: valid. verify-recovery-fix.py: local links, UTF-8/newline preservation, whitespace and 41 unique eval prompts pass. node --test tests/discovery.test.mjs tests/session-request.test.mjs tests/trace-evaluation.test.mjs: 5 tests, 3 passed, 0 failed, 2 skipped because actual candidate/legacy launcher variables are unavailable. Node v26.10.0. git diff --check passed in the formal source repo. Read-only review: git diff 4d3db01e5a20a6bcbff0b5fea001cfde22221b05 -- plus new ISSUE-0007; no unresolved findings. Requirements walked through helper omission, recoverable stale observation, provable versus unknown recovery budgets, and distinct Run stop decisions. These are source review/evaluation prompts, not authentic new Agent traces. No new runtime code or word-matching tests; no structure/build command exists in this Skill-only repo. No real account run or 30-minute acceptance, global installation, factory lock update, release or Git mutation.

## Activity log

### 2026-10-30 — Created

Issue created from the supplied project input.

### 2026-10-30 — Status changed from proposed to ready.

### 2026-10-30 — Status changed from ready to in-progress.

### 2026-10-30 — Status changed from in-progress to done.

## Completion summary

Corrected source Skill 2.1.2 persistence preparation, evidence reconciliation and per-Run closure decisions; added four evaluation prompts. Not released or installed; historical Runs and remote temporary helpers untouched.

## 2026-10-30 — Publication authorization

User explicitly requested commit, push and publication of Skill 2.1.2, plus an update/retest prompt for the other machine. This extends the earlier source-only scope to the ordinary source commit, main push, v2.1.2 tag, exact Git-blob ZIP and GitHub release. Keep historical account Runs, CLI/runtime, factory locks and local installed Skills unchanged. Real-Agent/30-minute acceptance remains outstanding and is not implied by publication.

## 2026-10-30 — Publication verified

Skill 2.1.2 已发布，源码及标签提交 939ae0aa78324ccc345c5c12a9aaed843c0d738c。GitHub 回读源码、资产 digest、独立下载哈希和 30 项 Git blob 对账均通过，详见 [发行记录](../release-2.1.2.md)。发布不替代真实 Agent/30 分钟验收；历史源修正阶段的未发布说明保持其时间语义。