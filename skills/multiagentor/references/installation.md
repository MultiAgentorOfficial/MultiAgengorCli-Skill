# Environment, installation, and version checks

Use npm as the only CLI distribution source. Do not clone, fetch, inspect, or download a CLI source repository.

## 1. Skill update gate

Run once at the start of each new workflow:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/update-skill.ps1
bash scripts/update-skill.sh
```

The updater compares `SKILL.md` `metadata.version`, validates the downloaded Skill, and replaces the complete installed Skill directory when newer. If it returns `updated: true`, stop and start a new Agent task so the new instructions load. Never run it during an active browser run.

## 2. CLI update gate

When no browser run is active, run once:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/update-cli.ps1
bash scripts/update-cli.sh
```

The updater reads `dist-tags.latest`, `engines.node`, and `dist.integrity` for `multiagentor-scenario-cli` from the npm registry. Requests bypass stale intermediary metadata caches so a newly published release is visible. It compares the live CLI version with the npm latest version and invokes the portable bootstrap when the CLI is missing, broken, or outdated. Parse its JSON and pin the returned `invocation` for the workflow. Use `-CheckOnly` or `--check-only` for a read-only check.

## 3. Inspect the environment

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/check-environment.ps1 -CheckRemote
bash scripts/check-environment.sh --check-remote
```

Confirm OS and architecture, Node/npm/NVM availability, resolved CLI path, live version/help, npm latest version, Node engine, registry, workspace, API base, and browser runtime override.

## 4. Resolve and pin the launcher

Prefer a path supplied by the user. Otherwise check `MULTIAGENTOR_CLI_PATH`, `multiagentor` on `PATH`, then the managed portable launcher. Keep the launcher, CLI version, Node runtime, npm package version, data directory, and API base unchanged during a run.

## 5. Existing Node or NVM installation

Read `engines.node` from live npm metadata before choosing Node. When a compatible Node and npm already exist, install or update with:

```text
npm install --global multiagentor-scenario-cli@latest
multiagentor --version
multiagentor --help
```

Respect the user's configured npm registry unless a registry was explicitly supplied. On Windows, verify `node --version` after `nvm use`; if the shared link did not switch, invoke the selected Node installation's `npm.cmd` directly with a process-local PATH.

## 6. No Node environment

Use the platform portable bootstrap. It:

1. Reads the latest CLI version and Node engine from npm metadata.
2. Selects the matching Node LTS archive for Windows x64 or Apple Silicon macOS.
3. Downloads the Node archive and `SHASUMS256.txt` from nodejs.org and verifies SHA-256.
4. Uses the bundled npm to install the exact npm latest CLI release into a staged user-local prefix.
5. Lets npm verify the package's published integrity metadata.
6. Verifies CLI version and help before replacing the previous managed package.
7. Creates a stable user-local launcher without changing machine-wide PATH.

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/bootstrap-portable-cli.ps1
bash scripts/bootstrap-portable-cli.sh
```

## 7. Verification

From a fresh process verify:

1. the launcher resolves to the intended installation;
2. Node satisfies npm `engines.node`;
3. CLI version equals the intended npm release;
4. `--help` succeeds and provides the live command surface;
5. the read-only workspace path operation succeeds;
6. no active run exists before changing CLI, Node, workspace, or browser runtime.

Do not use authentication, scenario download, or browser launch as an installation smoke test unless the user requested an end-to-end setup.

## 8. Browser runtime

The first browser start downloads and verifies MultiAgentBrowser. `MULTIAGENTOR_BROWSER_EXECUTABLE` may point to a prepared runtime using an absolute path. Do not substitute Playwright Chromium or ordinary system Chrome.

## Environment variables

| Variable | Purpose |
| --- | --- |
| `MULTIAGENTOR_CLI_PATH` | Launcher hint used by this Skill |
| `MULTIAGENTOR_API_URL` | Override the service API base URL |
| `MULTIAGENTOR_DATA_DIR` | Override the workspace with an absolute path |
| `MULTIAGENTOR_BROWSER_EXECUTABLE` | Use a prepared MultiAgentBrowser executable |

Run `multiagentor data path` before changing or migrating the workspace. Do not silently switch data roots during a workflow.
