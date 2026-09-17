# Environment, installation, and version checks

Run this gate before operating the CLI. The environment check is read-only; installation and updating change the local CLI installation.

## 1. Inspect the environment

Use the bundled Skill helper when possible:

```text
pwsh -NoProfile -File scripts/check-environment.ps1 [-CliRepo <path>] [-CheckRemote]
bash scripts/check-environment.sh [--cli-repo <path>] [--check-remote]
```

The helper reports facts and does not install or switch anything. Validate:

- OS and CPU architecture against the current CLI/browser support stated by repository HEAD;
- the active Node path/version and available NVM versions;
- the resolved CLI path, version, and whether help runs;
- source checkout version/commit, `engines.node`, and `packageManager`;
- optional remote HEAD when network access is available;
- effective workspace/API/runtime environment variables.

Read requirements from the current `package.json` and repository documentation. At the source revision used to create this Skill, browser execution supported Windows x64 and Apple Silicon macOS; verify this again rather than treating it as permanent.

When Node is missing or no installed/NVM version satisfies the CLI requirement, use the platform portable bootstrap:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/bootstrap-portable-cli.ps1
bash scripts/bootstrap-portable-cli.sh
```

Parse the final JSON object and preserve its `invocation` value for the entire workflow. The scripts install under the current user's application data, never modify machine-wide PATH, and keep Skill/CLI data separate.

## 2. Resolve and pin the launcher

Prefer the user-provided command or path. Otherwise check `MULTIAGENTOR_CLI_PATH`, `multiagentor` on `PATH`, then a local checkout containing `dist/bin/multiagentor.js`.

For a JavaScript entrypoint, invoke it with the active Node.js executable:

```text
node <repository>/dist/bin/multiagentor.js --version
node <repository>/dist/bin/multiagentor.js --help
```

For the installed shim:

```text
multiagentor --version
multiagentor --help
```

Keep the resolved launcher, source revision, CLI version, Node runtime, workspace, and API base unchanged through the workflow. Record them for the final report.

## 3. Check versions

Check four identities separately:

1. Skill version from `metadata.version` in this Skill's `SKILL.md` frontmatter.
2. Running CLI version from its live version command.
3. Installed/local source commit and package version when a checkout or package root is available.
4. Official CLI repository HEAD from a read-only remote query.

An equal package version does not prove equal source when development builds reuse a version number. Compare commits when possible. A newer remote commit is informational during ordinary operation. Update when the user requests it, when no CLI is installed, or when the current workflow needs a capability/fix absent from the pinned CLI.

`metadata.version` in `SKILL.md` is the single Skill version source. Do not maintain or trust a second version file. The Skill performs a read-only freshness check by default and never replaces its own loaded instructions automatically. When the user asks to update the Skill, require a clean checkout, use a fast-forward-only update from its configured origin, validate the new `SKILL.md`, then stop and ask for a new Agent task so the new instructions load.

Never update the CLI, Node symlink, workspace, or browser runtime during an active run.

## 4. Select Node with NVM

Read the `engines.node` range from the selected source revision. Use `nvm list` to find a matching installed runtime. On Windows, `nvm use <version>` may not change the symlink inside a restricted host; verify with `node --version`. If it did not switch, call that version's `node.exe`, `npm.cmd`, or `corepack.cmd` directly for the install/build commands.

Package-manager lifecycle scripts resolve `node` from the child process `PATH`. When directly selecting an NVM runtime, prepend that runtime directory to the command's process-local `PATH` and verify `node --version` inside the same process before installing dependencies. Calling a selected `node.exe` for only the package-manager entry script is insufficient if its child scripts still resolve a different system Node.

Install a new Node version only when none of the existing NVM runtimes satisfies the repository requirement and installation is part of the requested setup.

### No Node environment

The portable bootstrap performs the complete clean-machine path:

1. Detect and reject unsupported OS/architecture.
2. Obtain the current CLI source from its configured Git repository, or use a caller-supplied source directory.
3. Read `engines.node` and `packageManager` from that source.
4. Select the matching Node LTS platform archive from the official Node distribution index.
5. Download the archive and `SHASUMS256.txt`, then verify SHA-256 before extraction.
6. Install Node in a user-local versioned runtime directory.
7. Install the exact pnpm version declared by the CLI source.
8. Install dependencies with the frozen lockfile and build the CLI.
9. Generate a stable launcher that always uses the portable Node and built CLI entrypoint.
10. Verify the launcher with live version and help calls, then return its path as JSON.

Use `--check-only` / `-CheckOnly` for a non-mutating readiness check. On authenticated or private GitLab deployments, provide a prepared source checkout when archive or Git authentication is unavailable. Never put access tokens into script arguments or logs.

## 5. Install or update from the CLI repository

The CLI repository currently states that the package has not been successfully published to npm. Do not claim that `npm install -g multiagentor-scenario-cli` is available unless the registry is checked and the user asked to use it.

Clone the official source into a stable location, or fetch its configured remote and select the intended revision. Do not overwrite an unrelated dirty checkout. Read `packageManager` from `package.json`, then use that package manager/version to install and build. A typical current flow is:

```text
pnpm install
pnpm build
npm install -g .
multiagentor --version
multiagentor --help
```

Repository: `https://gitlab.kuajingvs.com/com-bifang-workspace/multiagengorcli`

Prefer the lockfile's frozen mode for reproducibility. If Corepack cannot verify package-manager signatures, use an already installed matching package-manager version or the selected Node runtime's npm to install that exact version; do not silently fall back to a different major.

The global local-directory install links back to the checkout. Preserve that checkout and its dependencies; after source updates reinstall dependencies when the lockfile changed, rebuild, and verify the global shim again.

If global installation is unsuitable, use `node dist/bin/multiagentor.js` directly from the built checkout.

## 6. Verify installation

From a fresh process, verify:

1. command resolution points to the intended shim or JavaScript entrypoint;
2. Node version satisfies `engines.node`;
3. CLI version and help complete successfully;
4. the reported command surface matches the selected source revision;
5. the read-only workspace path operation succeeds;
6. no active run exists before changing workspace or runtime settings.

Do not use authentication, scenario download, or browser launch as an installation smoke test unless the user asked for an end-to-end setup.

## 7. Browser runtime

The first browser start downloads and verifies MultiAgentBrowser. `MULTIAGENTOR_BROWSER_EXECUTABLE` may point to a prepared runtime using an absolute path. Do not substitute Playwright Chromium or an ordinary system Chrome.

## Environment variables

| Variable | Purpose |
| --- | --- |
| `MULTIAGENTOR_CLI_PATH` | Agent-side launcher hint used by this Skill |
| `MULTIAGENTOR_API_URL` | Override the service API base URL |
| `MULTIAGENTOR_DATA_DIR` | Override the workspace with an absolute path |
| `MULTIAGENTOR_BROWSER_EXECUTABLE` | Use a prepared MultiAgentBrowser executable |

Run `multiagentor data path` before changing or migrating the workspace. Do not silently switch data roots during a workflow.
