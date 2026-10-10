# Execution workflow

Use operation names, arguments, JSON fields, and states discovered from the pinned CLI version. This reference defines the sequence and decision points.

## 1. Preflight

1. Complete the environment and version gate from [installation.md](installation.md).
2. Complete live capability discovery from [dynamic-discovery.md](dynamic-discovery.md).
3. Confirm the same launcher, Node runtime, workspace, API base, and account will be used for every command and the foreground process.
4. Inspect active runs. Resolve any Profile conflict before creating another run.

## 2. Authenticate

Use the discovered read-only authentication status operation. Login only when required and follow [authentication.md](authentication.md). Complete MultiAgentor authorization through the CLI OAuth device flow in the user's default browser. Website credentials and verification belong only in the visible persistent MultiAgentBrowser.

After login, re-read status and record the non-sensitive account identity and API base. Never expose the returned token.

## 3. Resolve a task, then discover or obtain a scenario

First resolve tasks using [guided-workflow.md](guided-workflow.md) section 2a. For an existing selected task, read its already downloaded scenario manifest/instructions through discovered local paths; do not run scenario get or silently change its local version. Only when no task resolves the scenario:

1. Search through the CLI using the user's goal.
2. Present a small set of actual names and IDs when selection is ambiguous.
3. Obtain the selected scenario explicitly.
4. Read every returned local path, especially the manifest and Agent instructions.
5. Derive parameter schema, allowed behavior, success criteria, stop conditions, timeouts, and evidence requirements from this exact scenario version.

Do not assume a fixed scenario metadata schema. Do not execute metadata as code.

Before identity preparation, resolve tasks using [guided-workflow.md](guided-workflow.md) section 2a. An unchanged reused task supplies its browser and parameters. Do not create, import or reconfigure identity resources just to repeat an existing task.

## 4. Prepare a browser identity

1. List and inspect existing identities.
2. Reuse one only when its OS/browser/proxy/purpose/login state fits the scenario.
3. If no identity is resolved, ask for the identity source; create only when explicitly selected, using live supported values.
4. Configure the requested proxy before login or execution.
5. If site login or verification is required, open the persistent visible browser and let the user complete it directly.
6. Close the manual browser and verify the Profile is no longer active.

Cookie and browser bundle operations handle sensitive plaintext. Discover supported schemas and modes from the current CLI. Do not promise that a bundle carries storage types absent from the current implementation.

## 5. Create or reuse a task

1. List/inspect first: explicit task ID wins; one matching task is reused, multiple candidates require selection, no match collects missing inputs before creation.
2. Bind exact scenario and browser IDs from the same account/workspace.
3. Materialize validated non-secret parameters in the input form accepted by the live CLI.
4. Explain configuration differences and obtain explicit consent before update or Run; never silently overwrite reference accounts. Inherit unspecified values.
5. Inspect the resulting task and verify all effective fields before launch.

For task-memory scenarios, read [task-memory.md](task-memory.md), verify capabilities, and read the selected task namespace. Persona mismatch or missing memory capability blocks interaction. Each Run pins the matching persona version; new observations cannot rewrite its goal.

## 6. Start the foreground run

1. Start `task run <taskId> --transport local` in a persistent foreground process; the main Agent executes directly.
2. Capture the initial event, run ID, status, scenario version, browser ID, and scenario instruction path.
3. Read the run-specific scenario instructions again.
4. Confirm the describe action schemas for this pinned binary. The main Agent reads the pinned scenario, parameters and current page snapshots.
5. Follow [supervised-execution.md](supervised-execution.md) until terminal; no child Agent or step lease is used.

Starting is not completing. Do not detach unless the user explicitly asks for start-only behavior and the CLI supports safe later supervision.

## 7. Close, inspect, and report

1. Send the local terminal `close` request through run request with precise status/reason and optional scenarioResult. Verify the run-finished event.
2. Wait for the matching response and final event.
3. Use separate read-only run inspection/log operations when needed.
4. Read the actual result/evidence file and verify the Profile lock was released.
5. Report the Skill version, CLI/npm package version, Node runtime, workspace/API base, scenario/version, task/run/browser IDs, effective non-sensitive parameters, terminal status/reason, action counts, and artifact paths.

Browser action success is not business success. Determine outcome from the scenario's current terminal condition and observed page.
