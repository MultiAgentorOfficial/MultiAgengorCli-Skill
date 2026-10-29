import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtemp, writeFile, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { resolve, join } from "node:path";
import test from "node:test";
const helper = resolve("skills/multiagentor/scripts/session-request.mjs");
test("prepares UTF-8 exclusively and sends one pinned request without replay on uncertainty", async () => {
  const root = await mkdtemp(join(tmpdir(), "ma-request-helper-"));
  try {
    const params = join(root, "params.json"), request = join(root, "request.json"), cli = join(root, "cli.mjs"), calls = join(root, "calls.jsonl");
    await writeFile(params, JSON.stringify({ action: "click", params: { ref: "current" } }));
    const prepare = () => spawnSync(process.execPath, [helper, "prepare", "--request-file", request, "--request-id", "click-1", "--action", "act", "--params-file", params], { encoding: "utf8", windowsHide: true });
    const first = prepare(); assert.equal(first.status, 0, first.stderr);
    assert.deepEqual(JSON.parse(await readFile(request, "utf8")), { protocolVersion: "1.0", requestId: "click-1", action: "act", params: { action: "click", params: { ref: "current" } } });
    assert.notEqual(prepare().status, 0);
    await writeFile(cli, `import {appendFileSync} from 'node:fs';appendFileSync(${JSON.stringify(calls)},JSON.stringify(process.argv.slice(2))+'\\n');console.log(JSON.stringify({error:{code:'LOCAL_RESPONSE_UNKNOWN'}}));process.exitCode=1;`);
    const send = spawnSync(process.execPath, [helper, "send", "--cli", cli, "--run", "run-1", "--request-file", request, "--view", "agent"], { encoding: "utf8", windowsHide: true });
    assert.equal(send.status, 1); assert.match(send.stdout, /LOCAL_RESPONSE_UNKNOWN/);
    assert.deepEqual(JSON.parse((await readFile(calls, "utf8")).trim()), ["run", "request", "run-1", "--request-file", request, "--view", "agent"]);
  } finally { await rm(root, { recursive: true }); }
});
