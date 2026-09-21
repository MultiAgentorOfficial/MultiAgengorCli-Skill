# Execution workflow

Use operation names, arguments, JSON fields, and states discovered from the pinned CLI version. This reference defines the sequence and decision points.

## 1. Preflight

1. Complete the environment and version gate from [installation.md](installation.md).
2. Complete live capability discovery from [dynamic-discovery.md](dynamic-discovery.md).
3. Confirm the same launcher, Node runtime, workspace, API base, and account will be used for every command and the foreground process.
4. Inspect active runs. Resolve any Profile conflict before creating another run.

## 2. Authenticate

Use the discovered read-only authentication status operation. Login only when required and follow [authentication.md](authentication.md). MultiAgentor credentials belong only in the local secure input window. Website credentials and verification belong only in the visible persistent MultiAgentBrowser.

After login, re-read status and record the non-sensitive account identity and API base. Never expose the returned token.

## 3. Discover and obtain a scenario

1. Search through the CLI using the user's goal.
2. Present a small set of actual names and IDs when selection is ambiguous.
3. Obtain the selected scenario explicitly.
4. Read every returned local path, especially the manifest and Agent instructions.
5. Derive parameter schema, allowed behavior, success criteria, stop conditions, timeouts, and evidence requirements from this exact scenario version.

Do not assume a fixed scenario metadata schema. Do not execute metadata as code.

## 4. Prepare a browser identity

1. List and inspect existing identities.
2. Reuse one only when its OS/browser/proxy/purpose/login state fits the scenario.
3. Otherwise create one using values supported by the live CLI/service response.
4. Configure the requested proxy before login or execution.
5. If site login or verification is required, open the persistent visible browser and let the user complete it directly.
6. Close the manual browser and verify the Profile is no longer active.

Cookie and browser bundle operations handle sensitive plaintext. Discover supported schemas and modes from the current CLI. Do not promise that a bundle carries storage types absent from the current implementation.

## 5. Create or reuse a task

1. List tasks and inspect candidates before creating one.
2. Bind exact scenario and browser IDs from the same account/workspace.
3. Materialize validated non-secret parameters in the input form accepted by the live CLI.
4. Create or update only the requested resource.
5. Inspect the resulting task and verify all effective fields before launch.

## 6. Start the foreground run

1. Start the discovered task execution operation in a persistent PTY/process session with writable stdin.
2. Capture the initial event, run ID, status, scenario version, browser ID, and scenario instruction path.
3. Read the run-specific scenario instructions again.
4. Discover/confirm the active JSONL protocol and action schemas for this pinned binary.
5. Follow [supervised-execution.md](supervised-execution.md) until terminal.

Starting is not completing. Do not detach unless the user explicitly asks for start-only behavior and the CLI supports safe later supervision.

## 7. Close, inspect, and report

1. Send the protocol's terminal action with a precise status and reason.
2. Wait for the matching response and final event.
3. Use separate read-only run inspection/log operations when needed.
4. Read the actual result/evidence file and verify the Profile lock was released.
5. Report the Skill version, CLI/npm package version, Node runtime, workspace/API base, scenario/version, task/run/browser IDs, effective non-sensitive parameters, terminal status/reason, action counts, and artifact paths.

Browser action success is not business success. Determine outcome from the scenario's current terminal condition and observed page.
