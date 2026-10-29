# Main-Agent supervised execution

Default to local transport, retaining one foreground owner process until terminal. No child Agent, Worker lease or writable terminal stdin is required. Discover task.run, run.request, run.response and the relevant session actions first.

## Start and pin

Start `multiagentor task run <taskId> --transport local` in a persistent foreground process with readable output. Capture the small run-started event, Run ID and skillPath; read that fixed scenario before business actions. Use the same launcher, account, workspace and API base for every command. Missing local transport blocks startup; the removed stdio/Worker protocols cannot be used as fallback.

## Requests and bounded responses

Write one UTF-8 JSON file using the existing request envelope:

```json
{"protocolVersion":"1.0","requestId":"observe-1","action":"snapshot","params":{}}
```

Send `run request <runId> --request-file <absolute-json-path>`. Do not write JSON into PTY stdin. Request IDs are unique per intended action. An identical ID and normalized content returns the saved result or processing state without executing again; different content with the same ID is a conflict. Clean up request files after acknowledgement. Do not expose typed secrets or local channel credentials.

When response.agent-view is advertised, prefer run request/response --view agent under [efficient observation](efficient-observation.md); it presents already-persisted evidence and avoids routine full exports. Otherwise use the legacy JSON path below. Complete redacted responses are atomically saved in the Run directory. Above 12288 bytes the CLI returns a small receipt with responseFile, bytes and sha256. Read that file through file tools, or use the following cached reads; none visits the page or changes generation:

```text
run response <runId> --request-id observe-1 --pointer /data/elements --offset 0 --limit 20
run response <runId> --request-id observe-1 --output-file <new-absolute-path>
```

JSON Pointer selects data; pagination requires an array (limit 1–200). File export excludes selection/pagination and never overwrites. For selectionTooLarge narrow the pointer/page; do not repeat snapshot just to access cached text. Verify the receipt hash when transporting/exporting files. Processing is not failure: retrieve the same request later. Unknown after a crash requires fresh observation and business-state reconciliation before any new state-changing request.

## Observe, decide, verify

Read action schemas from describe instead of a static table. Use session.act for a verified action plus its latest observation:

```json
{"protocolVersion":"1.0","requestId":"type-1","action":"act","params":{"action":"type","params":{"ref":"<current-ref>","text":"<non-secret-value>"}}}
```

Envelope ok means the action request was processed; inspect data.actionCompleted, data.completion.status and data.error. VALUE_MISMATCH or a completion timeout is not business success. Type/select verification reports only status, never the actual value. For full observations use data.observation.snapshot; for unchanged observations map previous refs with refMap and use the new generation/cursor. Opt-in delta consumers use the CLI-materialized agent view or its exact saved observation; do not manually reconstruct or read a later page as the old response. Pass baseObservationId only from the previous returned observation to request deduplication. Do not repeat an action after a completion or observation failure. Use `waitFor` only for `click`/`scroll`, with the described condition and bounded timeout. Omit it for every other action, including `goto`, `back` and `reload`; navigation uses default DOMContentLoaded completion. Verify the returned observation's URL and page content against the expected destination, even when completion is `met`.

Valid local request envelopes (replace placeholders with the intended URL or current refs):

```json
{"protocolVersion":"1.0","requestId":"goto-1","action":"act","params":{"action":"goto","params":{"url":"https://example.com/"}}}
{"protocolVersion":"1.0","requestId":"back-1","action":"act","params":{"action":"back","params":{}}}
{"protocolVersion":"1.0","requestId":"reload-1","action":"act","params":{"action":"reload","params":{}}}
{"protocolVersion":"1.0","requestId":"click-1","action":"act","params":{"action":"click","params":{"ref":"<current-ref>"},"waitFor":{"kind":"url-change","timeoutMs":10000}}}
{"protocolVersion":"1.0","requestId":"scroll-1","action":"act","params":{"action":"scroll","params":{"ref":"<current-ref>","deltaY":480},"waitFor":{"kind":"scroll-change","timeoutMs":10000}}}
```

 Snapshot returns scoped blocks/elements/generation, not a top-level text string. Require capabilities by their declared domain. Current refs/cursors belong to the current observation; a fresh snapshot invalidates earlier refs, while cached response reads do not.

After page-changing actions, consume the action-returned observation or obtain one fresh snapshot if none was returned, then verify the scenario result. On stale refs/cursors, observe again. If rendering is visibly incomplete, allow at most two additional observations within two seconds, always within the scenario's stricter remaining budget; no networkidle or fixed stabilization wait. Preserve original deadlines, counters, candidates, progress and pending random decisions across all recovery.

Before a toggle or uncertain write, verify the current target and state. Already-desired state needs no action. Lost responses first use the durable cache; an uncertain effect requires fresh business-state verification before deciding to act again. A successful CLI action alone does not establish business success. Only scenario-defined reading dwell uses wait; ignore deprecated initial/feed/scroll delays.

## Target positioning and local observation

When independent positioning is required, discover `session.reveal` and `session.act` under the pinned contract and require browser capability `action.reveal` before starting. Send the usual local envelope with `action: "act"` and `params: {"action":"reveal","params":{"ref":"<current-ref>"}}`. Reveal only scrolls the current target and its scroll containers; it neither clicks nor navigates. It accepts no `waitFor`. A completed visible target yields `completion.status: "met"` and a new observation; the direct session.reveal interface returns `{ "visible": true }`.

Consume the returned observation, using fresh refs/refMap, to recheck the same business target and interaction state before clicking. Visibility does not establish clickability or business permission. Hidden, detached, stale or unstable targets require fresh observation within the scenario's recovery budget; never fall back to coordinates or another driver. An element removed by a feed refresh cannot be recovered by reveal alone; use the scenario's stable-identity recovery procedure.

Prefer action-returned observations and current block/cursor supplementation over repeated whole-page snapshots. Cached response pagination does not change refs; a new page observation does. Use ordinary click's automatic scroll when no independent pre-click observation is needed, and record positioning separately from feed advancement. Never bypass intent journaling, pending reconciliation or business-state verification to reduce calls.

## Manual intervention and close

Keep the visible browser open for user login/verification. Never request or type passwords, verification codes or CAPTCHA. Resume with a fresh observation within original budgets.

Send session.close with the truthful status, reason and optional scenarioResult through run request. The CLI stores close acceptance before cleanup and the final response before channel removal. Retrieve the close response, wait for run-finished, inspect terminal status/result.json and Profile release. Owner interruption requires separate run inspection/cancellation and an honest cleanup report; do not claim success from browser closure.

If the required business condition cannot be verified while active (for example a field value absent from snapshots), use the scenario's permitted partial/failure status when closing for evidence. Evaluate final screenshots afterward and report that later evidence separately. Never rewrite the terminal status or original scenarioResult to turn a post-close finding into an earlier success.

## Unpublished factory scenarios

Use only the factory-prepared explicit package and fixed Profile. Describe scenario.run and start its returned invocationArgs/environment; it uses the same run request/response/close protocol. This authoring Run is separate from authenticated Workspace tasks and cannot provide task memory. Memory-dependent scenarios require a Workspace Task. Do not treat local authoring as service publication.

For optional current navigation image evidence, read [visual verification](visual-verification.md). Existing start/end evidence files do not establish live visual verification.
