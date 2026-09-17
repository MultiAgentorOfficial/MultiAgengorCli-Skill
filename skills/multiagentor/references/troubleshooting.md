# Troubleshooting and workspace migration

## Diagnose in this order

1. Run the resolved launcher with `--version` and `--help`.
2. Run `data path` and confirm the effective workspace.
3. Run `auth status` for protected operations.
4. Inspect the selected scenario, browser, task, and run using read-only commands.
5. Read bounded run logs and `result.json`.
6. Use the error code and recovery field from CLI JSON output. Do not replace it with a guess.

Common conditions:

- `AUTH_REQUIRED`: log in or refresh the current account session.
- `PROFILE_BUSY`: inspect active runs; wait for or cancel the owner. Do not delete lock files while the owner may still run.
- Browser start/runtime failure: verify supported OS/architecture, runtime download/integrity, and `MULTIAGENTOR_BROWSER_EXECUTABLE` when explicitly configured.
- Proxy failure: validate the configured browser proxy and Windows upstream proxy chain. The CLI does not silently fall back to direct access.
- Stale or uncertain element target: take a new snapshot and reselect from observed role/name. Do not replay an old click.
- `pending: true` after cancellation: inspect the same run until it becomes terminal.
- Cleanup uncertainty: verify the run status and Profile availability before retrying.

Avoid retrying a click, form submission, upload, message, purchase, or other action that may have succeeded externally until the resulting page or service state is checked.

## Workspace location

```text
multiagentor data path
```

| Platform | Default path |
| --- | --- |
| Windows | `<user-home>/.multiagentor-scenario-cli` |
| macOS | `<user-home>/Library/Application Support/multiagentor-scenario-cli` |
| Other POSIX | `$XDG_DATA_HOME/multiagentor-scenario-cli` or `<user-home>/.local/share/multiagentor-scenario-cli` |

The workspace includes tokens, proxy credentials, database records, Profiles, downloaded scenarios, and run evidence. Keep it private.

## Migration

When the CLI reports `DATA_MIGRATION_REQUIRED`, first inspect locations with `multiagentor data path`. Close all CLI processes and managed browsers using the source workspace, then run:

```text
multiagentor data migrate --from <absolute-source-directory>
```

Migration copies into the effective destination and preserves the source. It does not merge an existing destination or delete old data. Do not manually remove `.migration.lock` or staging directories until the owning process is confirmed stopped and the contents have been inspected.

After migration, run `data path`, `auth status`, and read-only lists. Open the intended browser profile manually to verify retained login state before starting a business task.
