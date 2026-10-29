import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { evaluateTrace } from "../skills/multiagentor/evals/evaluate-trace.mjs";
const fixtures = JSON.parse(await readFile(new URL("../skills/multiagentor/evals/trace-cases.json", import.meta.url), "utf8"));
test("trace evaluation accepts literal reference decisions for all six controlled branches", () => {
  for (const scenario of fixtures.cases) {
    const events = scenario.required.map((event, i) => ({ ...event, sourceRef: `synthetic:${i}` }));
    const result = evaluateTrace(scenario, events);
    assert.equal(result.passed, true, JSON.stringify(result));
    assert.equal(result.agentBehaviorVerified, false);
  }
});
test("trace evaluation rejects duplicate clicks, skipped terminal checks and forbidden identity creation", () => {
  const linked = events => events.map((event, i) => ({ ...event, sourceRef: `synthetic:${i}` }));
  const lost = fixtures.cases.find(c => c.id === "lost-reply");
  const duplicate = evaluateTrace(lost, linked([...lost.required, { operation: "run.request", requestId: "click-2", action: "click" }]));
  assert.equal(duplicate.sourceLinked, true);
  assert.ok(duplicate.violations.some(message => message.startsWith("event count")));
  const close = fixtures.cases.find(c => c.id === "normal-close");
  const missingClose = evaluateTrace(close, linked(close.required.filter(e => e.operation !== "run.inspect")));
  assert.ok(missingClose.violations.some(message => message.includes("missing ordered event") && message.includes("run.inspect")));
  const reversed = evaluateTrace(close, linked([...close.required].reverse()));
  assert.ok(reversed.violations.some(message => message.startsWith("missing ordered event")));
  const reuse = fixtures.cases[0];
  const identity = evaluateTrace(reuse, linked([...reuse.required, { operation: "browser.create" }]));
  assert.ok(identity.violations.some(message => message.includes("forbidden event") && message.includes("browser.create")));
  const unlinked = evaluateTrace(reuse, reuse.required);
  assert.equal(unlinked.sourceLinked, false);
  assert.equal(unlinked.passed, false);
});
