# Codex isolated worker execution

The CLI owns the browser and does not call a model. The main Agent owns the business goal, deadlines, concise progress and final Run outcome. A fresh child observes and executes one bounded business step. Required system instructions and tools still come from the host; `fork_turns="none"` excludes parent conversation history, not host instructions.

## Capability and owner setup

Require the host's `spawn_agent` with `fork_turns="none"`. The published CLI introduces worker mode in 0.3.0; inspect the pinned CLI help for `--worker-session`, `run step-start`, `run step-end`, `run observe`, `run act`, and `run finish`. A matching package version alone is insufficient. Missing host support is `UNSUPPORTED_HOST`; missing commands are `UNSUPPORTED_WORKER_SESSION`. Stop without fallback.

Start `task run <taskId> --worker-session` in a persistent process. Capture `run-started`, Run ID and `skillPath`, but do not request an initial page observation in the main Agent. Read the pinned scenario and effective parameters, define its scenario deadline and any separate login/browsing deadlines according to the scenario. Browser startup happens once per Run.

Before each step, calculate remaining scenario milliseconds and call:

```text
run step-start <runId> --remaining-ms <ms>
```

Defaults are 20 actions and 120000ms. Use `--max-actions` or `--duration-ms` only for explicit scenario overrides. Duration cannot exceed the supplied remaining scenario budget. Do not restart deadlines, counters, random draws or retry budgets at worker handoff.

Spawn a fresh child with `fork_turns="none"`. Include the complete worker instructions below, pinned launcher/runtime and non-secret workspace/API environment, Run ID, CLI step lease ID/deadline, business step ID, bounded goal, observable completion condition, relevant allowed/forbidden behavior, effective parameters and concise progress. For a .cmd launcher use PowerShell's call operator; for a JS entrypoint use its pinned compatible Node runtime. Do not provide raw snapshots, mail/post bodies, credentials, session descriptor files, full previous reports or parent conversation history. Never ask the child to load the global Skill and repeat setup/update gates.

## Worker instructions (include in every child prompt)

1. Observe once with `run observe <runId> --step <leaseId>` without a baseline ID. This provides this child's full baseline. Read visible state from `snapshot.blocks`, targets from `snapshot.elements`, scroll scope from `scope`, and clipping from `truncated`/`stats`. There is no top-level snapshot `text`.
2. Write an owned UTF-8 JSON request file, then call `run act <runId> --step <leaseId> --request-file <path>`. Request shape: `{action,params,baseObservationId?,waitFor?}`. Pass the latest `observationId` as `baseObservationId` for deduplication. Supported actions: `goto:{url}`, `click:{ref}`, `type:{ref,text}`, `select:{ref,value}`, `scroll:{deltaY,ref?}`, `wait:{ms}`, `back:{}`, `reload:{}`. Use a current container/descendant ref for nested scrolling. Do not send `snapshot`, `screenshot`, `close` or arbitrary script actions. These shapes are subject to the pinned installed CLI contract.
3. Every action waits for execution and its bounded completion checks, then returns the latest `observation`. Consume it before selecting a new target; do not add an observe after every action. `mode=full` replaces the baseline. `mode=unchanged` omits repeated body text: retain the current baseline, apply `refMap` to all `elements.ref` and block `elementRefs`, update `generation` and `observationId`. Every old ref is invalid. Unknown/missing mappings or a lost baseline require a full observe without a base ID. Never guess or pass refs to the next child. Explicit recovery observe can use `--base-observation <id>` only with a retained valid baseline.
4. For click/scroll prefer supported `waitFor:{kind,timeoutMs?}`: `url-change`, `scroll-change`, `target-detached`. `target-detached` needs a target ref. Default timeout is 10000ms, supported range 1–30000ms, bounded by the step budget. With no explicit condition, click/scroll sample every 300ms until stable, at most 1500ms. A stable page or `completion.status=not-specified` does not establish business success. Navigation waits for DOMContentLoaded; type/select verify values; wait returns an observation after its requested duration. Do not use arbitrary conditions or require networkidle.
5. Inspect `actionCompleted`, `completion` (`met`, `timeout`, `not-specified`, `failed`) and `error.stage` (`validation`, `action`, `completion`, `observation`). A successful action may have a timed-out condition. `actionCompleted=true` with observation failure means recover observe, never replay. An action error or lost response may also have page effects: observe and check whether the goal already happened before considering a safe bounded retry. Timeout does not automatically repeat an action.
6. Verify the business completion condition from the latest state. Page state may change after a response; stale refs require re-observation, never target substitution. Stop on completion, budget/deadline exhaustion, unsafe/no-progress state, user stop or login/verification. Login/verification returns `needs-user`; do not enter credentials or wait through manual handling in this child.
7. Return only JSON `{stepId,status,verified,summary,observationId,actionCount,errorCode}` where `stepId` identifies the business step, `status` is `completed`, `needs-user` or `failed`, and `verified` is true only for an observed business result. `summary` contains only concise non-sensitive progress/counter updates, unresolved business work and the exact reason. A safe bounded slice can complete while the overall browsing goal remains pending. No page body, names, subjects, raw snapshot, screenshots or refs in this summary. Remove owned request files. Never issue step-start, step-end, finish, cancel, or start another Run.

Example request:

```json
{"action":"scroll","params":{"ref":"<current-container-ref>","deltaY":640},"baseObservationId":"<latest-id>","waitFor":{"kind":"scroll-change","timeoutMs":10000}}
```

## Main Agent handoff and finish

Wait for the child to terminate, then `run step-end <runId> --step <leaseId>`. Start the next child only after revocation. `ACTION_BUSY` means an action is still in flight; `STEP_BUSY` means the previous lease remains. Interrupt an over-budget child, wait for it/in-flight work to settle and revoke before handoff. Do not refresh the scenario deadline to rescue a timed-out step. A retry keeps the original business attempt budget even when a new lease is needed.

For `needs-user`, end the step and ask the user to act in the visible browser. Keep the owner process alive within the scenario's manual/scenario deadline; after user continuation start a fresh child with a full baseline. Main does not inspect the page itself. No child waits through a 900-second login window under a default 120-second lease.

Apply summary progress without double-counting iterations. Preserve counters, anonymous visited fingerprints, selected query/random decision, bounded retry state, and deadlines needed by the next step; never preserve full body text or old refs. If an identity cannot be safely carried as non-sensitive opaque progress, keep that complete operation in one child rather than reopening it by guesswork.

Only the main Agent finishes, after revoking the last step:

```text
run finish <runId> --status succeeded --reason <verified-scenario-reason>
```

Use failed/stopped according to scenario conditions. A completed business slice is not whole-Run success. Wait for owner termination, inspect Run/result/evidence and verify Profile release. Automatic evidence requires the corresponding permission; no removed screenshot action is needed. Current worker mode is for Workspace `task run`; it does not add worker mode to the no-subcommand local JSONL entrypoint. Explicit local legacy testing must be labeled as legacy and cannot prove worker acceptance.

## Privacy and measurements

Credentials in `worker-session.json`/`worker-step-*.json` are read automatically by CLI commands: never open or include them in prompts/logs. Loopback/step capabilities prevent accidental role crossover, not same-user OS file access. This is context isolation, not a security sandbox.

`latest-observation.json` holds local full page content; do not send it in the report. `result.json` exposes observationMetrics (explicit observes, internal samples, full/unchanged) and workerMetrics (step/action requests, response bytes). CLI step metrics alone cannot prove `fork_turns="none"`: inspect host child-session evidence during acceptance. Measure all child sessions for Token totals; bytes are not Tokens. Report unavailable measurements honestly.
