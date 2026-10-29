import { readFile, writeFile } from "node:fs/promises";
import { isAbsolute, extname } from "node:path";
import { parseArgs } from "node:util";
import { spawnSync } from "node:child_process";

// No discovery, retries, page interpretation or shell. Invoke with the pinned Node.
try {
  const { values: v, positionals } = parseArgs({ allowPositionals: true, strict: true, options: Object.fromEntries(
    ["request-file", "request-id", "action", "params-file", "cli", "run", "view"].map(key => [key, { type: "string" }])) });
  const required = key => { if (!v[key]) throw new Error("MISSING_ARGUMENT"); return v[key]; };
  const absolute = key => { const path = required(key); if (!isAbsolute(path)) throw new Error("ABSOLUTE_PATH_REQUIRED"); return path; };
  if (positionals.length !== 1 || !["prepare", "send", "read"].includes(positionals[0])) throw new Error("INVALID_MODE");
  if (v.view !== undefined && v.view !== "agent") throw new Error("INVALID_VIEW");
  if (positionals[0] === "prepare") {
    const raw = await readFile(absolute("params-file"));
    if (raw.length > 1_000_000) throw new Error("PARAMS_TOO_LARGE");
    const params = JSON.parse(new TextDecoder("utf-8", { fatal: true }).decode(raw));
    if (!params || typeof params !== "object" || Array.isArray(params)) throw new Error("PARAMS_OBJECT_REQUIRED");
    const requestId = required("request-id"), action = required("action");
    if (requestId.length > 128 || !/^[a-z]+$/.test(action)) throw new Error("INVALID_REQUEST");
    const requestFile = absolute("request-file");
    await writeFile(requestFile, JSON.stringify({ protocolVersion: "1.0", requestId, action, params }), { encoding: "utf8", flag: "wx", mode: 0o600 });
    console.log(JSON.stringify({ requestFile, requestId }));
  } else {
    const cli = absolute("cli"), run = required("run");
    const extension = extname(cli).toLowerCase();
    if (![".js", ".mjs", ".cjs", ".exe"].includes(extension)) throw new Error("PINNED_JS_OR_NATIVE_CLI_REQUIRED");
    const args = positionals[0] === "send" ? ["run", "request", run, "--request-file", absolute("request-file")]
      : ["run", "response", run, "--request-id", required("request-id")];
    if (v.view) args.push("--view", v.view);
    const child = spawnSync(extension === ".exe" ? cli : process.execPath, extension === ".exe" ? args : [cli, ...args],
      { encoding: "utf8", shell: false, windowsHide: true, maxBuffer: 2 * 1024 * 1024, timeout: 130_000 });
    if (child.stdout) process.stdout.write(child.stdout);
    if (child.stderr) process.stderr.write(child.stderr);
    if (child.error) throw new Error("REQUEST_OUTCOME_UNKNOWN_READ_SAME_ID");
    process.exitCode = child.status ?? 1;
  }
} catch (error) {
  console.error(error?.code === "EEXIST" ? "REQUEST_FILE_EXISTS" : /^(?:[A-Z_]+)$/.test(error.message) ? error.message : "REQUEST_HELPER_FAILED_READ_SAME_ID");
  process.exitCode = 1;
}
