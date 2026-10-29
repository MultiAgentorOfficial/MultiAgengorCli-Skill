import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

function matches(actual, expected) {
  if (!expected || typeof expected !== "object") return actual === expected;
  if (Array.isArray(expected)) return Array.isArray(actual) && actual.length === expected.length && expected.every((value, i) => matches(actual[i], value));
  return actual !== null && typeof actual === "object" && Object.entries(expected).every(([key, value]) => Object.hasOwn(actual, key) && matches(actual[key], value));
}

export function evaluateTrace(scenario, events) {
  if (!scenario?.id || !Array.isArray(scenario.required) || !scenario.required.length || !Array.isArray(events)) throw new Error("Expected a trace case and an event array");
  const violations = [];
  let cursor = 0;
  for (const expected of scenario.required) {
    const index = events.findIndex((event, i) => i >= cursor && matches(event, expected));
    if (index < 0) violations.push(`missing ordered event: ${JSON.stringify(expected)}`);
    else cursor = index + 1;
  }
  for (const forbidden of scenario.forbidden ?? []) if (events.some(event => matches(event, forbidden))) violations.push(`forbidden event: ${JSON.stringify(forbidden)}`);
  for (const count of scenario.counts ?? []) {
    const actual = events.filter(event => matches(event, count.match)).length;
    if (actual > count.max) violations.push(`event count ${actual} exceeds ${count.max}: ${JSON.stringify(count.match)}`);
  }
  const sourceLinked = events.length > 0 && events.every(event => typeof event?.sourceRef === "string" && event.sourceRef.trim().length > 0);
  if (!sourceLinked) violations.push("every normalized event needs a sourceRef to retained tool/decision evidence");
  return { caseId: scenario.id, passed: violations.length === 0, violations, sourceLinked, agentBehaviorVerified: false };
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const args = process.argv.slice(2);
    if (args.length !== 4 || args[0] !== "--case" || args[2] !== "--trace") throw new Error("Usage: node evaluate-trace.mjs --case <id> --trace <redacted-events.jsonl>");
    const cases = JSON.parse(await readFile(new URL("trace-cases.json", import.meta.url), "utf8"));
    const scenario = cases.cases.find(scenario => scenario.id === args[1]);
    if (!scenario) throw new Error("Unknown trace case");
    const events = (await readFile(args[3], "utf8")).split(/\r?\n/).filter(line => line.trim()).map(line => JSON.parse(line));
    const result = evaluateTrace(scenario, events);
    process.stdout.write(JSON.stringify(result) + "\n");
    if (!result.passed) process.exitCode = 1;
  } catch (error) { process.stderr.write(error.message + "\n"); process.exitCode = 1; }
}
