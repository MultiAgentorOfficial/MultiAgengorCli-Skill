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

1. **全局 npm 安装** — 使用系统 Node/npm 和 PATH 中的 CLI，适合已经统一配置开发环境的机器。
2. **受管独立安装** — 使用 Skill 管理的独立 Node 和 CLI，不修改系统 PATH，适合隔离环境或没有 Node 的机器。
3. **指定启动器路径** — 使用用户提供的 CLI 文件，适合已有自定义安装；后续全程固定该路径。

Also show the effective data directory and API base. Ask whether to keep them or use user-supplied values before creating resources:

1. **使用当前数据目录/API** — 继续使用现有登录、浏览器身份、任务和历史记录。
2. **指定数据目录/API** — 使用另一套隔离数据或服务地址；该选择会改变可见的账号和资源。

Once selected, pin them for the entire workflow.

## 2. MultiAgentor authentication gate

If `auth status` does not report `authenticated: true`, explain that MultiAgentor OAuth authorization is required and use [authentication.md](authentication.md). Open the visible OAuth flow; do not ask for an email, password, token, or code in chat. After the local window completes, run `auth status` again before continuing.

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
> 1. **复用已有身份** — 继续使用已有指纹、代理、Profile 和登录状态，不创建新环境。
> 2. **新建养号身份** — 创建全新的独立 Profile；系统和浏览器指纹由 Skill 自动检测，用户只需填写名称，代理信息可选。
> 3. **导入完整浏览器身份包** — 从 MultiAgentor 导出文件创建一个新身份，同时带入环境配置和 Cookies。
> 4. **向已有身份导入 Cookie** — 只给现有身份补充或替换 Cookies，不改变指纹、代理和环境。

Include actual existing browser names and IDs beneath option 1. If an option is unavailable, state why instead of silently selecting another.

### Reuse an existing identity

Ask the user to select an actual ID. Inspect it and show name, OS/browser fingerprint, proxy presence, and busy state without exposing secrets. A busy identity cannot be selected for another active run.

### Create a new identity

Query live help and any read-only service metadata for supported values. Ask for only:

- **浏览器名称（必填）** — 用于在身份列表中识别该 Profile。
- **代理信息（可选）** — 用户可跳过；只有用户选择配置时，再询问协议、主机、端口和是否需要认证。

Resolve the environment fingerprint without asking the user:

1. Set `--system-os` from the current host: `windows` on Windows or `macos` on macOS.
2. Set `--system-version` from the host version returned by the environment check.
3. Set `--kernel-brand chrome` unless live CLI help advertises a different required fixed value.
4. Set `--kernel-version` to the detected MultiAgentBrowser major when available; otherwise use the detected installed Google Chrome major.
5. Confirm that each resolved value satisfies the live CLI and service contract before creating the identity. If detection fails or the service rejects a value, report the exact missing or rejected field and stop identity creation. Do not turn these fields into user choices and do not invent a fallback value.

Show the resolved non-sensitive values for transparency, but do not ask for confirmation of each field. Build the command in this form:

```text
browser create --name <user-name> --system-os <detected-os> --system-version <detected-version> --kernel-brand <detected-or-cli-default-brand> --kernel-version <detected-major>
```

When the user skips proxy configuration, append no `--proxy-*` options. When the user supplies a proxy, append `--proxy-protocol`, `--proxy-host`, and `--proxy-port`; add authentication only through a secure input mechanism supported by the live CLI.

If the user wants a proxy, annotate each presented choice:

- **跳过代理** — 不传入任何代理参数，使用当前机器网络出口；后续仍可通过 `browser proxy` 配置。
- **配置代理** — 创建时绑定用户提供的代理，首次网站访问即使用该出口。
- **HTTP** — 使用普通 HTTP 代理协议，仅在代理服务明确要求时选择。
- **HTTPS** — 使用 HTTPS 代理协议，仅在代理服务明确提供该协议时选择。
- **SOCKS5** — 使用 SOCKS5 代理，适合明确提供 SOCKS5 地址的服务。
- **代理无需认证** — 只需要主机和端口。
- **代理需要认证** — 还需要用户名和密码；当前 CLI 没有安全密码输入时，改用已含代理的身份包。

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

- **`merge`（推荐）** — 保留现有 Cookies，并用导入文件增加或更新同名项；适合补充登录状态。
- **`replace`** — 删除现有 Cookies 后使用导入文件；可能让其他网站退出登录，必须明确确认。

Run the discovered `browser cookie-import` operation and report only the imported count, mode, and browser ID. Do not display Cookie values.

Explain that Cookie import changes only the selected identity's Cookies. It does not change the identity name, OS/browser fingerprint, environment, or proxy. Recommend `merge` unless the user explicitly needs replacement.

## 5. Website login and warm-up

Ask whether the chosen identity is already logged in to the target website.

Show these annotated choices:

1. **已登录，直接继续** — 保留当前 Profile 状态；运行前仍会标记登录状态为用户确认。
2. **现在打开可见浏览器登录/养号** — 打开持久化 MultiAgentBrowser，由用户完成密码、验证码、CAPTCHA 和必要的人工操作。
3. **暂时跳过登录** — 不打开手动浏览器；登录状态记为不确定，正式运行时建议选择可见模式。

- If no or uncertain, launch the persistent browser visibly without `--headless` and let the user complete login, verification, CAPTCHA, consent, and any warm-up actions.
- Keep the Agent waiting while the manual browser is open.
- After the user closes it, verify that the Profile is released before continuing.

For X/Twitter and other website accounts, the Agent never enters passwords, one-time codes, recovery codes, security keys, or CAPTCHA responses.

## 6. Task choice and parameters

List tasks bound to the selected scenario/browser. Ask:

1. **复用匹配任务** — 使用已有任务 ID 和原配置，适合重复执行同一场景；运行前展示当前参数。
2. **新建任务** — 创建独立任务并重新选择名称和参数，适合不同账号、目标或配置。

When creating, ask the user to choose the task name and every parameter required by the downloaded scenario manifest. For optional parameters, show each supported choice/default together with its meaning and effect; do not silently populate business values. Write non-secret parameters to a restricted temporary JSON file for `--params-file`; never put secrets in it.

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

The user must explicitly select one annotated mode for this run. Do not inherit the choice from an earlier run:

1. **可见模式（登录不确定时推荐）** — 显示 MultiAgentBrowser，用户可以观察流程并处理登录或验证。
2. **Headless 模式** — 后台运行、不显示浏览器；只适合登录状态明确且场景无需人工介入。

For the final action, show:

1. **确认并运行** — 使用上方汇总配置启动前台监督任务。
2. **返回修改** — 不启动任务，回到用户指定的选择步骤。
3. **取消** — 不创建新的运行；保留此前已明确创建或导入的资源。

## 8. Run and finish

Start the foreground run only after confirmation. Follow [supervised-execution.md](supervised-execution.md) to terminal state, inspect result/evidence files, verify Profile release, and report the resolved choices along with the outcome.

## Question style

- Ask one decision at a time unless several short fields belong to the same selected branch.
- Use numbered options. Every option must include a short user-facing annotation explaining what it does, when to use it, and its material effect. Never display bare option names.
- Include a recommended label only when supported by discovered state, and explain the reason in the same line.
- Show human-readable names together with IDs.
- Never ask the user to paste passwords, tokens, Cookie values, proxy credentials, verification codes, or recovery codes.
- Re-run read-only lists when the user waits long enough that state may have changed.

## Current CLI choice matrix

Use live help as the authority. For the current CLI family, the guided choices map to these operations:

| User decision | Current operation and required choices |
| --- | --- |
| Reuse identity | `browser list`, user selects ID, then `browser inspect` |
| Create identity | `browser create`; user enters a required name and may skip or provide proxy information; Skill auto-detects host OS, host version, kernel brand, and browser major |
| Import identity | `browser import`; user selects bundle path and optional new name |
| Import Cookies | `browser cookie-import`; user selects browser ID, Cookie file, and `merge` or `replace` |
| Configure proxy later | `browser proxy`; user selects remove or full protocol/host/port configuration |
| Website login/warm-up | `browser launch`; visible mode only, user performs credentials and verification |
| Select scenario | `scenario search`, then `scenario get`; user selects returned scenario ID |
| Reuse/create task | `task list`/`task inspect` or `task create`; user selects name and scenario parameters |
| Run task | `task run`; user selects visible or headless and confirms the resolved summary |

Do not offer fields absent from the live CLI. When a later CLI adds fields, discover them and add them to the user choices for that run.

For CLI `0.1.2`, `browser create` has this effective parameter contract:

| Parameter | CLI behavior | Skill source |
| --- | --- | --- |
| `--name` | Required; no CLI default | User enters it |
| `--system-os` | Required; no CLI default | Auto-detect current host as `windows` or `macos` |
| `--system-version` | Required; no CLI default | Auto-detect current host version |
| `--kernel-brand` | Optional; CLI defaults to `chrome` | Use live CLI default |
| `--kernel-version` | Required; no CLI default | Auto-detect MultiAgentBrowser major, then installed Chrome major |
| `--proxy-protocol`, `--proxy-host`, `--proxy-port` | Optional as a group; omitting every proxy option means no proxy | Ask only when the user chooses to configure a proxy |
| `--proxy-username`, `--proxy-password` | Optional authentication fields | Use only when the live CLI provides a secure secret input path |

Rebuild this table from live help and installed validation code when the CLI version changes.

For dynamic lists, annotate them too. Format scenario, browser, and task choices as:

```text
1. <name> (<id>) — <what it is for>; <relevant status or effect>
```

Examples of relevant annotations include scenario purpose/version, browser OS/Chrome/proxy/busy status, and task scenario/browser binding. Do not expose secret values.
