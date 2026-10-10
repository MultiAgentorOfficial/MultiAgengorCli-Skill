# Supervised JSONL execution

This is the default execution workflow. The main Agent owns one foreground JSONL session from startup through verified terminal closure. No child Agent or worker lease is required.

## Session setup

Start `multiagentor task run <taskId>` in a persistent interactive process. The first event has this shape:

```json
{"protocolVersion":"1.0","event":"run-started","run":{"id":"...","status":"running"},"skillPath":".../SKILL.md"}
```

Capture the run ID. Read `skillPath` before sending business actions; it is the fixed scenario procedure for this run. If the process ends before a `run-finished` event, inspect the run separately and report the interruption.

## Request and response

Send exactly one compact JSON object followed by a newline:

```json
{"protocolVersion":"1.0","requestId":"1","action":"snapshot","params":{}}
```

Each request ID must be non-empty and unique within the session. Wait for its response:

```json
{"protocolVersion":"1.0","requestId":"1","ok":true,"data":{}}
```

On `ok: false`, follow the returned code and message. Retry only when the cause is corrected and the business action is safe to repeat.

## Actions

| Action | Params | Notes |
| --- | --- | --- |
| `status` | `{}` | Current run and browser URL |
| `goto` | `{"url":"https://..."}` | HTTP(S) only; older binaries used navigate, confirm installed contract |
| `snapshot` | `{}` | Current CLI: blocks, elements, scope, generation, truncated, stats; no top-level text |
| `click` | `{"ref":"..."}` | Current snapshot ref only |
| `type` | `{"ref":"...","text":"..."}` | Current ref; text up to 10,000 chars; logs redact text |
| `select` | `{"ref":"...","value":"..."}` | Current select ref |
| `scroll` | `{"deltaY":480,"ref":"<current-container-ref>"}` | Ref optional; use a container/descendant ref for nested scroll, confirm bounds |
| `wait` | `{"ms":1000}` | Integer from 0 to 60,000 |
| `back` | `{}` | Browser back |
| `reload` | `{}` | Reload current page |
| `close` | `{"status":"succeeded|failed|stopped","reason":"..."}` | Finalize the run |

Current CLI captures evidence automatically with screenshot permission and has no explicit screenshot action. Inspect the pinned binary instead of sending removed actions from an older catalog.

Only use actions consistent with the downloaded scenario. The V2 CLI exposes a common action set; availability does not grant business intent.

## Observe, decide, act

1. Take a snapshot.
2. Compare the page with the scenario's next condition.
3. Choose one declared action using current observable evidence.
4. After any page-changing action, take another snapshot.
5. Check stop and success conditions before the next action.

Do not reuse element refs after `navigate`, `click`, `type`, `select`, `scroll`, `back`, or `reload`. Dynamic pages may also change between requests; if the target identity is not unambiguous, take another snapshot or stop instead of guessing.

An action returning `ok: true` does not show that the intended business result occurred. Verify the resulting page.

## Manual intervention

When authentication, CAPTCHA, or verification appears, keep the visible browser open and ask the user to complete it there. Do not request credentials in chat, type them, read Cookies, or bypass verification. After the user finishes, take a new snapshot.

## Closing

Use `succeeded` only after the scenario's success condition is observable. Use `failed` for a terminal error or unmet required outcome. Use `stopped` for user stop or an explicitly permitted partial run. No-progress termination follows the scenario contract (warmup scenarios require failed/three-no-progress-rounds).

```json
{"protocolVersion":"1.0","requestId":"final","action":"close","params":{"status":"succeeded","reason":"scenario-completed"}}
```

Wait for the matching response and the final `run-finished` event. Then inspect `resultPath` or run the separate inspect command and read `result.json`.

## Timing and recovery

Only scenario-defined reading dwell uses `wait`. Do not add fixed startup, loop, retry or stabilization sleeps. Navigation and element readiness are bounded conditions, not mandatory delays: continue immediately when ready. After a scroll, observe the actual viewport; if rendering is pending, refresh observation within the original bounded retry/deadline budget instead of replaying the scroll. Never require networkidle. Preserve original total/browsing/manual deadlines, counters, selected candidates and pending random decisions across recovery. Before opening a detail, reserve enough remaining browsing time for dwell, return and verification; otherwise skip the optional visit.

Ignore deprecated homeDelaySeconds, initialDelaySeconds, feedDelaySeconds, initialWaitSeconds and listScrollDelaySeconds from old tasks; never turn them into waits or show them as new choices.
