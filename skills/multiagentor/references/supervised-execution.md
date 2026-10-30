# Main-Agent supervised execution

Default to local transport, retaining one foreground owner process until terminal. No child Agent, Worker lease or writable terminal stdin is required. Discover task.run, run.request, run.response and the relevant session actions first.

## Start and pin

Start `multiagentor task run <taskId> --transport local` in a persistent foreground process with readable output. Capture the small run-started event, Run ID and skillPath. Reuse previously read scenario instructions only when their content digest matches this Run snapshot; otherwise read the fixed file before business actions. Use the same launcher, account, workspace and API base for every command. Missing local transport blocks startup; the removed stdio/Worker protocols cannot be used as fallback.

## Prepare scenario persistence

Before business actions, map the fixed scenario's required state to the actual persistence mechanism. If generating a local helper, inspect and dry-check its transitions using non-secret local fixtures without invoking the CLI or touching task memory. Cover selection, intent, verified or unknown effect, local failure/recovery, step settlement and finalization as applicable. A helper that initializes a retry counter but never increments/persists it does not cover recovery. The request helper only transports requests; it does not implement scenario checkpoints. Complete missing branches before interactions.

Use the scenario's field names and limits. Preserve its original phase deadlines (anchored to their actual start events), stable targets, draws, progress sets, pending effects and shared recovery stages/counts. Persist an extra attempt and its unchanged deadline before performing it; navigation or a new observation must not reset the shared budget. Record concluded steps with the scenario-required outcome, reason, evidence, next step, elapsed time and used recovery budget, including round-level recovery. Retain the actual error and request ID; a local observation error is not a checkpoint write error. Only batch statistics that can be rebuilt from durable events.

Where memory and local checkpoints mirror a cursor, publish the settled state after clearing that cursor; preserve pending until effect verification. Check write results and perform the scenario-required readback. A write failure prevents dependent new writes and follows the scenario's failure/reconciliation route. Do not silently switch to chat state or fabricate missing history.

## Requests and bounded responses

Write one UTF-8 JSON file using the existing request envelope:

```json
{"protocolVersion":"1.0","requestId":"observe-1","action":"snapshot","params":{}}
```

Send `run request <runId> --request-file <absolute-json-path>`. Do not write JSON into PTY stdin. Request IDs are unique per intended action. An identical ID and normalized content returns the saved result or processing state without executing again; different content with the same ID is a conflict. Clean up request files after acknowledgement. Do not expose typed secrets or local channel credentials.

Retrieve the same request's durable response until complete. A processing receipt is pending, not failure. On lost replies read the same request ID before any new action. After an unknown/crashed result, reconcile current business state before a state-changing request. For agent view, bounded receipts, cached selection/export and current observation formats, read [efficient observation](efficient-observation.md).

## Observe, decide, verify

Read action schemas from describe instead of a static table. Use session.act for a verified action plus its latest observation:

```json
{"protocolVersion":"1.0","requestId":"type-1","action":"act","params":{"action":"type","params":{"ref":"<current-ref>","text":"<non-secret-value>"}}}
```

Envelope ok means the request was processed. Inspect data.actionCompleted, data.completion.status and data.error, then verify the scenario's business post-state. Type/select verification reports status without the actual value. A completion timeout or observation error can follow an executed action; recover evidence before considering another action. [Efficient observation](efficient-observation.md) owns full/unchanged/delta handling and ref validity.

Use waitFor only for discovered supported action/condition combinations. Navigation uses the pinned default completion contract; verify destination identity from returned URL and content. Read the relevant descriptor instead of copying an old action table.

After page-changing actions, consume the action-returned observation or obtain one fresh snapshot if none was returned, then verify the scenario result. On stale refs/cursors, observe again. If rendering is visibly incomplete, allow at most two additional observations within two seconds, always within the scenario's stricter remaining budget; no networkidle or fixed stabilization wait. Preserve original deadlines, counters, candidates, progress and pending random decisions across all recovery.

Before a toggle or uncertain write, verify the current target and state. Already-desired state needs no action. Lost responses first use the durable cache; an uncertain effect requires fresh business-state verification before deciding to act again. A successful CLI action alone does not establish business success. Only scenario-defined reading dwell uses wait; ignore deprecated initial/feed/scroll delays.

## Reconcile a recording gap

On discovering a missing record, pause dependent business writes and compare the checkpoint, step/action journals, same-request durable responses and memory revision. Distinguish an omitted transition, a failed write, a stale mirror and an intentionally inapplicable metric. Null summary fields alone do not establish missing source evidence. Reconcile known effects without replaying verified interactions; recover counters or stages only when retained events establish their exact meaning under the fixed scenario. Record any later reconciliation with its sources and current timestamp; never backdate it or present it as an immediate historical checkpoint.

If critical state is provable, persistence is working and the scenario permits recovery, save the reconciled state and recheck the current target/safe page within the original remaining budgets before continuing. A recoverable local failure follows that scenario's skip/recovery route. If a required budget, identity, pending effect or gate remains unknown, do not guess zero, reset a deadline or resume dependent writes; follow the scenario's read-only or terminal route. Proven protocol violations retain their required failure outcome even when later evidence can explain them. Evaluate each Run separately; a shared reporting gap alone does not establish the same global failure in every Run.

## Target positioning and local observation

When independent positioning is required, discover `session.reveal` and `session.act` under the pinned contract and require browser capability `action.reveal` before starting. Send the usual local envelope with `action: "act"` and `params: {"action":"reveal","params":{"ref":"<current-ref>"}}`. Reveal only scrolls the current target and its scroll containers; it neither clicks nor navigates. It accepts no `waitFor`. A completed visible target yields `completion.status: "met"` and a new observation; the direct session.reveal interface returns `{ "visible": true }`.

Consume the returned observation, using fresh refs/refMap, to recheck the same business target and interaction state before clicking. Visibility does not establish clickability or business permission. Hidden, detached, stale or unstable targets require fresh observation within the scenario's recovery budget; never fall back to coordinates or another driver. An element removed by a feed refresh cannot be recovered by reveal alone; use the scenario's stable-identity recovery procedure.

Use ordinary click's automatic scroll when independent pre-click observation is unnecessary. Record target positioning separately from feed advancement; the scenario still owns intent journaling and result verification.

## Manual intervention and close

For login/verification inside an active Run, retain its visible browser and foreground owner while the user acts under [authentication](authentication.md). Resume from a fresh observation within original budgets.

Before an early close, record the applicable fixed-scenario stop condition and supporting evidence, unresolved critical state or proven protocol violation, plus any permitted recovery attempted or ruled out. "Cannot yet report compliant completion" does not by itself establish "must terminate now". Follow mandatory global stops promptly; do not bypass them merely to reach a requested duration. Derive status/reason and scenarioResult from that decision for this Run; do not hard-code failed/interactionIncomplete across Runs because a summary is incomplete. Before normal completion verify the scenario's final page, pending effects and original duration/other completion conditions; closing a browser is not that check.

Retain the non-secret close envelope (protocolVersion, requestId, action and actual params), together with the decision evidence, in the Run evidence before dispatch; redact sensitive values rather than retaining secret request files. Send session.close with the truthful status, reason and optional scenarioResult through run request. The CLI stores close acceptance before cleanup and the final response before channel removal. Retrieve the close response, wait for run-finished, inspect terminal status/result.json and Profile release. Owner interruption requires separate run inspection/cancellation and an honest cleanup report; do not claim success from browser closure.

If the required business condition cannot be verified while active (for example a field value absent from snapshots), use the scenario's permitted partial/failure status when closing for evidence. Evaluate final screenshots afterward and report that later evidence separately. Never rewrite the terminal status or original scenarioResult to turn a post-close finding into an earlier success.

## Unpublished factory scenarios

Use only the factory-prepared explicit package and fixed Profile. Describe scenario.run and start its returned invocationArgs/environment; it uses the same run request/response/close protocol. This authoring Run is separate from authenticated Workspace tasks and cannot provide task memory. Memory-dependent scenarios require a Workspace Task. Do not treat local authoring as service publication.

For optional current navigation image evidence, read [visual verification](visual-verification.md). Existing start/end evidence files do not establish live visual verification.

## Report

Report business outcome and exact stop reason; Skill/CLI/scenario versions and task/Run/Profile IDs; effective non-secret parameters and permissions; actual start/end time and action/progress counts; unknown effects or manual steps; cleanup confirmation and local result/screenshot/evidence paths. Use the scenario-defined outcome, not action counts or a clean close. Report Token measurements with their actual scope when available; unavailable measurements remain unavailable, never zero. Keep secrets and sensitive page bodies out of reports.
