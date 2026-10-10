---
id: ISSUE-0003
title: "Release local-only Skill"
status: done
priority: high
created: 2026-10-10
updated: 2026-10-10
closed: 2026-10-10
related_adrs: []
depends_on: []
---

# ISSUE-0003: Release local-only Skill

## Problem

Installed instructions still support retired execution interfaces.

## Desired outcome

Release Skill 2.0.0 using describe/local only and synchronize the authorized installation.

## Acceptance criteria

- [x] Retired interfaces are absent and current callers use describe/local.
- [x] Relevant controlled tests, build and review pass.
- [x] Versioned artifacts are packed and distribution is verified.
- [x] Authorized commits/pushes and release outcomes are recorded.

## Out of scope

External website/service writes, dependency changes and user data migration.

## Decisions

Skill 2.0.0 requires describe/local CLI 0.4.0+. Legacy probing is read-only for upgrade; it cannot authorize execution. worker-execution.md is a non-executable redirect retained solely because installed 1.x updater archive integrity requires that filename.

## Implementation notes

Pin installation identity and contractDigest once, query related operation descriptors on demand, use request files/cached responses and verified session.act. Recovery preserves budgets and reconciles uncertain effects. memory uses summary/export. Updated references, evals and README.

## Verification

Candidate/real legacy discovery tests: 2 passed; PowerShell environment preflight executionSupported=true with CLI 0.4.0. PowerShell parser, bash -n, UTF-8 scan and quick_validate passed. Independent Agent reused Task/Profile, performed goto/click/type with session.act, handled 60463-byte durable receipt and SHA-256, saved/read release-eval memory revision 5, and closed succeeded (Run c6bc2e90-94e2-46eb-85c5-91d7d1a6864d). One index discovery, 17 distinct descriptors, no repeated discovery/compiled-code inspection/Worker/PTY. Fixed-range review: git diff daacfe93f3d275de578101c979862eb980bc806e plus new scripts/tests; no open blocking findings. macOS shell syntax only, not live OS validation.

Release: source commit e18083f and annotated v2.0.0 pushed to main; GitHub release https://github.com/MultiAgentorOfficial/MultiAgengorCli-Skill/releases/tag/v2.0.0. Downloaded release ZIP SHA-256 matches 3c8c962a2588e6af2202a824f6b551c378a35ae848b44c9f21342276f36de0f3. Existing 1.7.0 updater successfully replaced the authorized Skill with 2.0.0 (integrityOk=true); post-update environment preflight reports CLI 0.4.0 and executionSupported=true. A new Agent session is needed to load installed instructions. Independent synthetic evidence copied to C:\Users\frank\AppData\Local\Temp\ma-release-local-040-1791618484016\independent-evidence.

## Activity log

### 2026-10-10 — Created

Issue created from the supplied project input.

### 2026-10-10 — Status changed from proposed to ready.

### 2026-10-10 — Status changed from ready to in-progress.

### 2026-10-10 — Status changed from in-progress to done.

## Completion summary

Published Skill 2.0.0 source/tag/ZIP and upgraded the authorized installation; independent forward execution succeeded with describe/local.
