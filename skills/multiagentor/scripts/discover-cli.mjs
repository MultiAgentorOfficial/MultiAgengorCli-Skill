import { spawnSync } from "node:child_process";
import { extname, resolve } from "node:path";
import { createHash } from "node:crypto";
import { readFileSync, realpathSync } from "node:fs";

// One bounded, non-PTY probe. stdout is decoded only after the subprocess exits.
const invocation = process.argv[2];
if (!invocation) throw new Error("CLI_PATH_REQUIRED");
function run(args) {
  const extension = extname(invocation).toLowerCase();
  const command = [".mjs", ".cjs", ".js"].includes(extension) ? process.execPath
    : process.platform === "win32" && [".cmd", ".bat"].includes(extension) ? process.env.ComSpec || "cmd.exe" : invocation;
  const commandArgs = command === process.execPath ? [invocation, ...args]
    : command !== invocation ? ["/d", "/s", "/c", "call", invocation, ...args] : args;
  return spawnSync(command, commandArgs, { encoding: "utf8", windowsHide: true, timeout: 15000, maxBuffer: 4 * 1024 * 1024 });
}
try {
  const probe = run(["describe"]);
  if (probe.error) throw probe.error;
  let contract = null;
  if (probe.status === 0 && probe.stdout.trimStart().startsWith("{")) {
    contract = JSON.parse(probe.stdout);
    if (contract.schemaVersion !== 1 || !/^[a-f0-9]{64}$/.test(contract.contractDigest ?? "") || !/^\d+\.\d+\.\d+(?:[-+].+)?$/.test(contract.cliVersion ?? "") || contract.requireCapabilitiesScope !== "browser" || !Array.isArray(contract.operations) || !["browser", "workspace", "transport"].every(scope => Array.isArray(contract.capabilities?.[scope]))) throw new Error("INVALID_CLI_CONTRACT");
  } else if (!(probe.status === 2 || /INVALID_COMMAND|unknown (?:command|argument)/i.test(probe.stderr) || probe.stdout.includes("scenario get") && probe.stdout.includes("task run"))) {
    throw new Error("CLI_DISCOVERY_FAILED");
  }
  const version = contract?.cliVersion ?? run(["--version"]).stdout.trim();
  if (!/^\d+\.\d+\.\d+(?:[-+].+)?$/.test(version)) throw new Error("INVALID_CLI_VERSION");
  let identity = invocation;
  try { const path = realpathSync(resolve(invocation)); identity = `${path}:${createHash("sha256").update(readFileSync(path)).digest("hex")}`; } catch { /* PATH launcher plus contract identity still pins this workflow. */ }
  const names = new Set(contract?.operations.map(item => item.operation) ?? []);
  const executionSupported = Boolean(contract && contract.transports?.length === 1 && contract.transports[0] === "local"
    && ["task.run", "run.request", "run.response", "session.act", "session.close", "scenario.run"].every(name => names.has(name)));
  console.log(JSON.stringify({ executionSupported, cliPath: invocation, cliVersion: version, cliHelpAvailable: contract ? false : run(["--help"]).status === 0,
    packageIdentity: contract?.runtime ?? { launcher: identity, version }, contractCacheKey: `${identity}:${version}:${contract?.contractDigest ?? "legacy"}`, cliContract: contract }));
} catch {
  console.error("CLI_DISCOVERY_FAILED: inspect the pinned launcher/runtime; do not start a Run or repair PTY JSON.");
  process.exitCode = 1;
}
