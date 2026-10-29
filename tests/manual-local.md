# Controlled local acceptance

Use a fresh Agent session, this source/locked Skill revision and an explicitly supplied candidate npm CLI. Skip updates. Use an isolated workspace, controlled loopback HTML and a test Profile. No external website writes.

## Fixed-receipt branches

Use `skills/multiagentor/evals/trace-cases.json` for six independently scoped requests: unique-task reuse, first creation, manual login, lost reply, unknown effect and terminal closure. Give the Agent the case prompt and controlled tool receipts, without the required/forbidden assertions. Record actual choices and tool requests in order. The fixture receipts are not evidence that an Agent chose correctly.

Retain the original redacted host tool/decision log. Normalize each event with operation, relevant lifted arguments/results and sourceRef pointing to that original record. Never omit extra actions or user questions. Run:

```text
node skills/multiagentor/evals/evaluate-trace.mjs --case <case-id> --trace <redacted-events.jsonl>
```

The checker verifies ordered required events, forbidden events and action-count bounds. Its agentBehaviorVerified remains false: sourceRef strings cannot attest a fresh Agent or authentic tool use. Review provenance and actual outcomes separately. Unit tests exercise synthetic checker examples only. Repeat each controlled case three times with fixed Skill/model/CLI inputs; require all critical constraints to pass before claiming behavioral acceptance. Record model identity as unknown if unavailable, never invent it.

## Runtime acceptance

1. Run one pinned preflight and discover relevant operations once. Check browser/workspace capability domains.
2. Resolve the fixed task/Profile under guided-workflow rules. Start local with stdin unavailable.
3. Exercise UTF-8 request files, bounded responses and cached paging/export; confirm cached reads preserve generation.
4. Exercise a lost reply and stale target using the exact same request identity and fresh current state; confirm no duplicate toggle.
5. Exercise memory revision CAS where declared. Close using supervised-execution rules and inspect native result plus Profile release.

Record actual commands, package/contract and locked-Skill digest, original/normalized trace paths and hashes, business result and cleanup. Compare the same input/model/environment before and after: document files/UTF-8 bytes loaded and available input/cached/output Token data. Label measurement scope and unavailable values. Synthetic fixtures, subprocess checks and static gates do not establish fresh-Agent behavior, website success or Token savings. macOS requires its own run; real-account interaction and publication retain their separate authorization gates.
