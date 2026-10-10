---
id: ISSUE-0001
title: "默认复用已有任务并支持任务 memory"
status: done
priority: high
created: 2026-10-10
updated: 2026-10-10
closed: 2026-10-10
related_adrs: []
depends_on: []
---

# ISSUE-0001: 默认复用已有任务并支持任务 memory

## Problem

通用引导重复询问复用选择，未定义任务目标冲突和 memory 使用边界。

## Desired outcome

唯一匹配任务自动复用，冲突需明确同意，支持场景声明的 memory 能力与恢复。

## Acceptance criteria

- [x] All scenarios reuse one matching task; ambiguity asks, no match creates only after collecting missing configuration.
- [x] Conflicting supplied parameters require explicit consent; busy browsers do not cause replacement resources.
- [x] Task memory discovery and recovery are documented; Skill validates and factory locks the project-local revision.

## Out of scope

No automatic scheduling, account-switch detection, cloud memory, cross-task persona sharing, unrelated refactoring or dependency additions. Publishing and live external writes have separate gates.

## Decisions

User approved the full plan on 2026-10-10. Task owns memory; Workspace owns persistence/CAS/identity/Run restrictions. CLI owns no X rules; Skill owns task selection and consent; scenario owns source-derived persona, matching and allowed interactions. Public Workspace methods and CLI subprocesses are the test seam. Reusing records avoids a shallow storage wrapper and keeps future storage changes internal. First persona displays and continues; changed references need explicit consent. Per Run 1800–3600 seconds, at most 10 follows/30 likes. Existing X/Gmail semantics remain unchanged.

## Implementation notes

Skill candidate 1.9.0 resolves tasks before identity creation or scenario replacement. One candidate reuses, ambiguity asks, no match collects only missing business inputs; unchanged explicit execution authorization is retained. Config conflicts wait for agreement; busy resources are not replaced. Memory reference documents capability/CAS/current Run checkpoints, frozen goal and pending recovery. Updated contradictory legacy guidance and eval expectations. No distribution or global Skill changes.

Read-only review: `git diff b3240fe8783743875b0e22fccda3a81e1c25efe5 -- .`, plus new task-memory.md and local Issue records. Fixed unconditional identity questions and scenario-get before reuse. No remaining P0/P1 instruction findings.

## Verification

Skill结构校验通过；新增8项eval并更新2项旧预期，人工语义对照完成，未宣称执行模型评测；工厂sync/status current=true，锁定digest 64132f244063fd9184b3c0a808af4291003682ff759c8712ae59574d33ea68db。

## Activity log

### 2026-10-10 — Created

Issue created from the supplied project input.

### 2026-10-10 — Status changed from proposed to ready.

### 2026-10-10 — Status changed from ready to in-progress.

### 2026-10-10 — Status changed from in-progress to done.

## Completion summary

Skill1.9.0默认优先复用任务，冲突等待同意并定义任务memory恢复；工厂锁定副本已同步，未分发。
