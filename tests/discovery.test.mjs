import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtemp, writeFile, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";

const helper = resolve("skills/multiagentor/scripts/discover-cli.mjs");
test("discovers an actual npm candidate once and rejects a damaged contract", { skip: !process.env.MULTIAGENTOR_CONTRACT_TEST_CLI }, async () => {
  const root = await mkdtemp(join(tmpdir(), "ma-skill-discovery-"));
  try {
    const launcher = join(root, "cli.mjs"), calls = join(root, "calls.jsonl"), target = process.env.MULTIAGENTOR_CONTRACT_TEST_CLI;
    await writeFile(launcher, `import {spawnSync} from 'node:child_process';import {appendFileSync} from 'node:fs';
      appendFileSync(${JSON.stringify(calls)},JSON.stringify(process.argv.slice(2))+'\\n');
      if(process.argv[2]!=='describe')process.exit(97);
      const r=spawnSync(process.execPath,[${JSON.stringify(target)},...process.argv.slice(2)],{stdio:'inherit'});process.exit(r.status ?? 1);`, "utf8");
    const result = spawnSync(process.execPath, [helper, launcher], { encoding: "utf8", windowsHide: true });
    assert.equal(result.status, 0, result.stderr);
    const found = JSON.parse(result.stdout);
    assert.equal(found.cliContract.schemaVersion, 1);
    assert.equal(found.cliHelpAvailable, false);
    assert.equal(found.executionSupported, true);
    assert.ok(found.cliContract.capabilities.workspace.includes("task.memory.revision"));
    assert.equal(await readFile(calls, "utf8"), '["describe"]\n');
    await writeFile(launcher, `import {spawnSync} from 'node:child_process';
      const r=spawnSync(process.execPath,[${JSON.stringify(target)},'describe'],{encoding:'utf8'});const d=JSON.parse(r.stdout);d.schemaVersion=999;console.log(JSON.stringify(d));`, "utf8");
    const invalid = spawnSync(process.execPath, [helper, launcher], { encoding: "utf8", windowsHide: true });
    assert.equal(invalid.status, 1); assert.match(invalid.stderr, /CLI_DISCOVERY_FAILED/);
  } finally { await rm(root, { recursive: true, force: true }); }
});

test("inspects an actual legacy launcher without replacing it", { skip: !process.env.MULTIAGENTOR_LEGACY_TEST_CLI }, () => {
  const result = spawnSync(process.execPath, [helper, process.env.MULTIAGENTOR_LEGACY_TEST_CLI], { encoding: "utf8", windowsHide: true });
  assert.equal(result.status, 0, result.stderr);
  const found = JSON.parse(result.stdout);
  assert.equal(found.executionSupported, false);
  assert.equal(found.cliContract, null); assert.equal(found.cliHelpAvailable, true);
});
