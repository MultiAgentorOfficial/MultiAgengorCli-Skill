# Guided workflow for every scenario run

Use this interview for each request that will create, configure, or run a task. Perform read-only discovery first so questions contain real choices. Do not ask the user for information available from the CLI.

Honor an answer already given in the current request, but still show the resolved choice in the final pre-run summary. Never start a run until the browser identity source has been explicitly chosen for this run.

## 1. Silent preflight

Before asking workflow questions:

1. Complete the Skill, CLI, environment, and live-interface gates.
2. Run `auth status`, `data path`, `browser list`, `task list`, and `run list` through the pinned launcher when supported.
3. Detect active runs and busy Profiles.
4. If authenticated, run scenario search/list using the user's stated goal.

Report a blocking installation or authentication problem immediately. Otherwise use the results to offer concrete names and IDs.

When more than one usable CLI environment exists, ask the user which to use:

1. detected global npm installation;
2. managed portable npm installation;
3. a launcher path supplied by the user.

Also show the effective data directory and API base. Ask whether to keep them or use user-supplied values before creating resources. Once selected, pin them for the entire workflow.

## 2. MultiAgentor authentication gate

If `auth status` does not report `authenticated: true`, explain that MultiAgentor account login is required and use [authentication.md](authentication.md). Do not ask for the email or password in chat. After the local window completes, run `auth status` again before continuing.

## 3. Confirm the scenario

When the user did not provide an exact scenario ID/version:

1. Ask for the automation goal or search terms if still unclear.
2. Run `scenario search`; show a short list of actual scenario names, IDs, and relevant descriptions.
3. Ask the user to select one.
4. Run `scenario get`, then read its manifest and instructions before asking for parameters.

Do not offer scenario import: the current CLI has search/get/list but no scenario import command.

## 4. Required browser identity question

Ask this for every new task/run, after listing current browser identities:

> 这次任务使用哪种浏览器身份？
> 1. 复用已有身份
> 2. 新建养号身份
> 3. 导入完整浏览器身份包
> 4. 向已有身份导入 Cookie

Include actual existing browser names and IDs beneath option 1. If an option is unavailable, state why instead of silently selecting another.

### Reuse an existing identity

Ask the user to select an actual ID. Inspect it and show name, OS/browser fingerprint, proxy presence, and busy state without exposing secrets. A busy identity cannot be selected for another active run.

### Create a new identity

Query live help and any read-only service metadata for supported values. Then ask the user to choose every creation field supported by the current CLI; do not silently infer or randomize them:

- identity name;
- system OS: `windows` or `macos`;
- system version;
- kernel brand when the CLI offers more than its current `chrome` default;
- Chrome major version;
- proxy timing: configure now, configure later, or no proxy;
- proxy protocol: HTTP, HTTPS, or SOCKS5;
- proxy host and port;
- whether the proxy requires authentication.

Present detected host values only as labeled recommendations. The user must select the values used to create the identity. Do not invent a system version or Chrome major that the live CLI/service has not accepted or advertised.

Do not request proxy passwords in chat. If the CLI only accepts proxy secrets as process arguments, explain the limitation and ask the user to use an imported identity that already contains the proxy, or wait for a secure CLI input mode.

Create the identity, inspect the returned object, then ask whether to open the visible browser now for website login or account warm-up.

### Import a complete identity bundle

Ask for the local bundle path and optional new name, then summarize that the import creates a new identity and that the file may contain sensitive plaintext configuration and Cookies. Run the discovered equivalent of:

```text
browser import --file <bundle.json> [--name <name>]
```

Inspect the returned identity and use its new ID. Do not print, quote, or commit bundle contents.

For the current CLI, a version 1 `multiagentor-browser` bundle carries the identity name, OS/system fingerprint, browser kernel/version, proxy configuration when present, environment configuration, and Cookies. It creates a new ID and never overwrites an existing identity. Explain that it is not a complete Chrome user-data directory and does not promise to contain history, extensions, local storage, or every website state.

### Import Cookies

Ask for an existing browser ID, local Cookie JSON path, and mode:

- `merge`: preserve existing Cookies and merge imported entries;
- `replace`: replace existing Cookies and therefore requires explicit confirmation.

Run the discovered `browser cookie-import` operation and report only the imported count, mode, and browser ID. Do not display Cookie values.

Explain that Cookie import changes only the selected identity's Cookies. It does not change the identity name, OS/browser fingerprint, environment, or proxy. Recommend `merge` unless the user explicitly needs replacement.

## 5. Website login and warm-up

Ask whether the chosen identity is already logged in to the target website.

- If no or uncertain, launch the persistent browser visibly without `--headless` and let the user complete login, verification, CAPTCHA, consent, and any warm-up actions.
- Keep the Agent waiting while the manual browser is open.
- After the user closes it, verify that the Profile is released before continuing.

For X/Twitter and other website accounts, the Agent never enters passwords, one-time codes, recovery codes, security keys, or CAPTCHA responses.

## 6. Task choice and parameters

List tasks bound to the selected scenario/browser. Ask whether to reuse a matching task or create a new one. When creating, ask the user to choose the task name and every parameter required by the downloaded scenario manifest. For optional parameters, show the supported choices/defaults and ask which to use; do not silently populate business values. Write non-secret parameters to a restricted temporary JSON file for `--params-file`; never put secrets in it.

Inspect the final task and show its task ID, scenario ID/version, browser ID, and non-sensitive parameters.

## 7. Required pre-run confirmation

Before `task run`, present one compact summary and ask the user to confirm:

- scenario name, ID, and version;
- task name and ID;
- browser identity name, ID, and source: reused, newly created, bundle import, or Cookie import;
- proxy presence without credentials;
- visible or headless mode;
- non-sensitive scenario parameters;
- whether website login was verified or remains uncertain.

If login is uncertain, recommend visible mode. Do not start on an ambiguous “use whatever is available” assumption.

The user must explicitly select visible or headless mode for this run. Do not inherit the choice from an earlier run.

## 8. Run and finish

Start the foreground run only after confirmation. Follow [supervised-execution.md](supervised-execution.md) to terminal state, inspect result/evidence files, verify Profile release, and report the resolved choices along with the outcome.

## Question style

- Ask one decision at a time unless several short fields belong to the same selected branch.
- Use numbered options and include a recommended option only when supported by discovered state.
- Show human-readable names together with IDs.
- Never ask the user to paste passwords, tokens, Cookie values, proxy credentials, verification codes, or recovery codes.
- Re-run read-only lists when the user waits long enough that state may have changed.

## Current CLI choice matrix

Use live help as the authority, but for CLI `0.1.0` the guided choices map to these operations:

| User decision | Current operation and required choices |
| --- | --- |
| Reuse identity | `browser list`, user selects ID, then `browser inspect` |
| Create identity | `browser create`; user selects name, OS, system version, Chrome major, and proxy configuration |
| Import identity | `browser import`; user selects bundle path and optional new name |
| Import Cookies | `browser cookie-import`; user selects browser ID, Cookie file, and `merge` or `replace` |
| Configure proxy later | `browser proxy`; user selects remove or full protocol/host/port configuration |
| Website login/warm-up | `browser launch`; visible mode only, user performs credentials and verification |
| Select scenario | `scenario search`, then `scenario get`; user selects returned scenario ID |
| Reuse/create task | `task list`/`task inspect` or `task create`; user selects name and scenario parameters |
| Run task | `task run`; user selects visible or headless and confirms the resolved summary |

Do not offer fields absent from the live CLI. When a later CLI adds fields, discover them and add them to the user choices for that run.
