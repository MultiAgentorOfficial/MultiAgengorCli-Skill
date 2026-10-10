---
id: ISSUE-0002
title: "Contract-first discovery and reliable local execution"
status: done
priority: high
created: 2026-10-10
updated: 2026-10-10
closed: 2026-10-10
related_adrs: []
depends_on: []
---

# ISSUE-0002: Contract-first discovery and reliable local execution

## Problem

Skill discovers arguments from help and compiled code and routes large JSON through an interactive terminal.

## Desired outcome

Discover contracts on demand, supervise local transport, reconcile documentation and recovery rules.

## Acceptance criteria

- [x] Contract-first discovery and local foreground execution replace routine source inspection and PTY parsing.
- [x] README, references and evals agree; legacy/read-only recovery and memory output are documented.
- [x] Static and fresh-session controlled validation are recorded honestly.

## Out of scope

No commit, push, publication, global installation replacement, external website writes, migrations or new dependencies.

## Decisions

User explicitly authorized the full plan. CLI owns contracts/transport; Skill owns discovery/supervision; Factory owns dependency gates. Preserve stdio/Worker behavior.

## Implementation notes

Updated source Skill to 1.10.0: one preflight, pinned package/digest cache, describe on demand, capability domains, default local transport, bounded cached reads, memory summary/export, bounded recovery and truthful post-close evidence. README/references/evals no longer prescribe Worker defaults. Global Skill and factory's existing production lock were not replaced; validation used an isolated factory working-tree lock.

Independent fresh Agent used locked snapshot 794eb95254717e6c33465c6c9f92f292e4c8f859399a3e2880c63833b85f8624, Skill 1.10.0, npm candidate CLI 0.3.3 and Node 22.23.3. One environment probe/index and 17 distinct operation queries; no help/version repeat, compiled-code read, Worker lease, PTY or replacement resources. Reused task/profile/scenario, exercised goto/snapshot/click/type, saved and read memory revision 5, retrieved durable close reply and inspected Profile release.

Run 36319294-fb1c-4d80-b685-5135069c577e ended stopped, not succeeded: textbox values are absent from snapshots; final screenshot confirmed synthetic input only after close. Preserve original failedStep=input-verification and report later evidence separately. This observed gap led to an explicit truthful-close rule; no browser value/website-specific readiness changes. result.json SHA256 390f3b563bb7bbfcec6a693b8a2db508b146af460eb342a376f08d09de1dc2fa; end.png SHA256 e2e1ad8fda02571d6b1d2c1c99a61ee787d20b53875c29f30decaca1a5256e76. Temporary fixture and its request files were disposed by their owner after review. Final source also includes reference consistency corrections after that evaluated snapshot.

Review range git diff daacfe93f3d275de578101c979862eb980bc806e plus new helper/tests. No remaining P0/P1 finding. macOS runtime and a real website rerun were not performed.

## Verification

Windows / Node 22.23.3: discovery.test.mjs passed 2 tests against the installed final npm candidate and the unchanged managed legacy CLI. python -X utf8 quick_validate.py passed. PowerShell check-environment candidate preflight passed; bash -n passed for both updated shell scripts. Independent fresh-session main-Agent validation used only the locked Skill and describe contracts, exercised local browser actions and memory, and verified durable closure/Profile release. The run correctly remained stopped because input value was only confirmed by a post-close screenshot; this is partial business verification, not a succeeded scenario. Review and git diff --check passed. macOS runtime and external website replay remain untested.

## Activity log

### 2026-10-10 — Created

Issue created from the supplied project input.

### 2026-10-10 — Status changed from proposed to ready.

### 2026-10-10 — Status changed from ready to in-progress.

### 2026-10-10 — Status changed from in-progress to done.

## Completion summary

Implemented Skill 1.10.0 contract-first discovery, supervised local transport, bounded recovery and consistent documentation; recorded the partial fresh-session business verification honestly.
