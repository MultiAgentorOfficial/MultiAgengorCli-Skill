# Dynamic CLI and API discovery

Do this once at the start of every MultiAgentor workflow. Keep the resulting capability map in working memory for that workflow; do not copy a static command catalog into the final answer.

## 1. Resolve the executable and runtime

Resolve the exact launcher and record its path. Query its version and full top-level help. If Node is incompatible, inspect installed NVM versions and use an available Node version satisfying the CLI package's `engines` field. On Windows, NVM may fail to switch the shared symlink inside a restricted host; invoking the selected version's `node.exe` directly is valid.

Do not combine output from different launchers or workspaces.

## 2. Build the capability map from the installed CLI

Use live help first. Extract command groups, subcommands, required identifiers, options, mutating behavior, foreground behavior, and environment variables.

When help is insufficient, inspect the files belonging to the executed installation:

1. Resolve the shim or JavaScript entrypoint.
2. Locate the adjacent package root and `package.json`.
3. Search its README/docs, compiled command router, protocol definitions, and browser action implementation.
4. Search by the command/action name rather than assuming a fixed file path.

Useful search targets in the current repository layout include `workspace-commands`, `protocol`, `browser-run`, `contract`, `HELP`, `parseArgs`, and action validation schemas. These names are hints; use file search because the layout can change.

The source and compiled files associated with the running binary outrank this Skill and the remote repository.

## 3. Consult the official repository when local detail is absent

Official CLI repository:

`https://gitlab.kuajingvs.com/com-bifang-workspace/multiagengorcli`

Use read-only access to inspect its current HEAD, README, CLI reference, package metadata, command router, contracts, and changelog. Compare the installed version/commit with repository HEAD. If they differ, do not apply a new-source-only command to the old binary. Either use the installed interface or update the CLI as part of the requested outcome.

Do not edit the CLI repository when the task is to operate or update this standalone Skill.

## 4. Learn the live data model

Run current read-only status/list/inspect/path operations and inspect the returned JSON. Determine identifiers, names, versions, states, paths, pagination, and optional fields from the actual response. Preserve unknown fields and avoid positional parsing of JSON.

The service API can evolve. Use the CLI as the compatibility boundary. Do not call undocumented raw endpoints or fabricate response fields. If the CLI rejects a changed API response, record the exact error, compare the installed CLI with repository HEAD, and update or diagnose the CLI rather than guessing an endpoint.

## 5. Learn each scenario and run protocol

After obtaining a scenario, read every returned local path. Read its manifest and Agent instructions. Scenario metadata is dynamic: derive parameters, allowed behavior, success conditions, timeouts, and evidence expectations from the current package without assuming a fixed metadata schema.

When a run starts, inspect its initial event and scenario path. Discover supported JSONL actions and parameter schemas from the running version's local package/compiled validation code and from protocol errors. Use only capabilities confirmed for this version and consistent with the scenario.

## 6. Re-discover on change

Repeat discovery when any of these changes during the task:

- launcher, version, source commit, data directory, or API base;
- help output or JSON shape;
- authentication account;
- downloaded scenario version;
- protocol version or advertised action surface.

Report a version/schema mismatch explicitly. Do not silently fall back to remembered commands.
