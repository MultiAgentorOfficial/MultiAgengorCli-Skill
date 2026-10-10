# MultiAgentor CLI Skill

让 AI Agent 通过自然语言安装和使用 `multiagentor-scenario-cli`，完成场景查找、浏览器身份管理、任务执行和结果检查。

例如，安装 Skill 后，可以在 Codex 中发送：

```text
使用 $multiagentor，检查我的环境并安装当前 MultiAgentor CLI，然后引导我选择一个官方场景运行。
```

Agent 会检查环境、引导登录、列出实际可用的场景和浏览器身份，确认参数后执行任务，并报告业务结果和证据路径。

本仓库提供 Skill 指令、参考文档和辅助脚本。CLI 从 npm 安装，执行场景还需要 MultiAgentor 账号、服务端可用的场景和 MultiAgentBrowser 浏览器运行时。

## 使用前准备

| 项目 | 要求 |
| --- | --- |
| 操作系统 | Windows x64 或 Apple Silicon macOS；当前便携安装脚本不支持 Linux 和 Intel Mac |
| Agent 宿主 | 能加载本地 Skills、读取文件并执行本机命令；本文以 Codex 为例 |
| 默认执行模式 | Main Agent directly owns a foreground JSONL process with writable stdin and readable stdout; no child Agents |
| 网络 | 安装和更新需要访问 GitHub、npm registry、nodejs.org；登录和执行还需要访问 MultiAgentor 服务及场景目标网站 |
| 账号 | 执行服务端场景需要完成 MultiAgentor OAuth 授权；目标网站要求登录时，由用户在可见浏览器中完成 |
| Node.js | 可以预先安装，也可以由辅助脚本下载并校验便携 Node.js；版本要求以当前 npm 包的 `engines.node` 为准 |

Default runs use `task run <taskId>` directly in the main Agent. Historical worker commands remain compatible but are not part of the Skill execution workflow.

## 安装 Skill

安装 Skill 和安装 CLI 是两个步骤：先让 Codex 能发现 `multiagentor`，再通过它检查或安装 CLI。

### 方式一：让 Codex 安装

在 Codex 中发送以下提示词，安装本仓库中的 Skill 子目录：

```text
使用 $skill-installer，从以下 GitHub 目录安装 multiagentor Skill：
https://github.com/MultiAgentorOfficial/MultiAgengorCli-Skill/tree/main/skills/multiagentor
安装完成后告诉我实际安装路径。
```

安装后新建一个聊天，再发送本文的首次使用提示词。如果宿主未提供 `skill-installer`，使用下面的手动方式。

### 方式二：手动复制

获取本仓库后，复制完整的 `skills/multiagentor` 文件夹，包括其中的 `agents`、`references` 和 `scripts`，不要只复制 `SKILL.md`。

可以在 GitHub 页面选择 **Code → Download ZIP** 并解压，也可以使用 Git：

```text
git clone https://github.com/MultiAgentorOfficial/MultiAgengorCli-Skill.git
cd MultiAgengorCli-Skill
```

当前 Codex 的本地 Skill 发现目录如下，参见 [Codex 官方安装目录说明](https://learn.chatgpt.com/docs/build-skills#where-codex-loads-local-skills)：

| 安装范围 | Windows | macOS |
| --- | --- | --- |
| 用户级，供多个项目使用 | `%USERPROFILE%\.agents\skills\multiagentor` | `~/.agents/skills/multiagentor` |
| 项目级，只供目标项目使用 | `<项目目录>\.agents\skills\multiagentor` | `<项目目录>/.agents/skills/multiagentor` |

以下命令从本仓库根目录执行，将 Skill 安装到用户级目录。目标已存在时会停止，请先确认已有副本的来源和用途。

**Windows PowerShell：**

```powershell
$skillSource = Join-Path (Get-Location).Path 'skills\multiagentor'
$skillParent = Join-Path $env:USERPROFILE '.agents\skills'
$skillDestination = Join-Path $skillParent 'multiagentor'
if (Test-Path -LiteralPath $skillDestination) {
    throw "目标已存在，请先检查已有 Skill：$skillDestination"
} else {
    New-Item -ItemType Directory -Path $skillParent -Force | Out-Null
    Copy-Item -LiteralPath $skillSource -Destination $skillDestination -Recurse
    Test-Path -LiteralPath (Join-Path $skillDestination 'SKILL.md')
}
```

最后一条命令应输出 `True`。

**macOS Terminal：**

```bash
skill_source="$PWD/skills/multiagentor"
skill_parent="$HOME/.agents/skills"
skill_destination="$skill_parent/multiagentor"
if [[ -e "$skill_destination" || -L "$skill_destination" ]]; then
  printf '目标已存在，请先检查已有 Skill：%s\n' "$skill_destination"
else
  mkdir -p "$skill_parent" &&
    cp -R "$skill_source" "$skill_destination" &&
    test -f "$skill_destination/SKILL.md" &&
    printf 'Skill 已安装：%s\n' "$skill_destination"
fi
```

安装后的结构应为：

```text
.agents/skills/
└── multiagentor/
    ├── SKILL.md
    ├── agents/
    ├── evals/
    ├── references/
    └── scripts/
```

使用自定义启动器或已有专用 Skill 目录时，以当前 Codex 实例实际加载的位置为准，避免在多个目录重复安装同名副本。项目级安装时，将目标目录换为目标项目的 `.agents/skills`，并在该项目中打开 Codex。

### 验证是否加载

新建聊天并输入以下提示词：

```text
请确认你能找到 multiagentor Skill。只读取 SKILL.md，报告它的路径和 metadata.version，不运行安装、更新或浏览器任务。
```

应能看到实际 Skill 路径和版本。Codex CLI 或 IDE 扩展也可通过 `/skills` 或输入 `$` 查找；Skill 的界面显示名称是 **MultiAgentor CLI**。未出现时，检查目录结构并重启 Codex，参见 [官方 Skill 使用说明](https://learn.chatgpt.com/docs/build-skills#how-chatgpt-and-codex-use-skills)。

## 首次使用

### 1. 检查环境并安装 CLI

在已加载 Skill 的聊天中发送：

```text
使用 $multiagentor，检查当前电脑环境并安装 MultiAgentor CLI。
如果缺少 Node.js，使用受管便携安装。完成后报告 CLI 启动器路径、版本和帮助检查结果，先不要启动浏览器任务。
```

Skill 会从 npm 获取 CLI 的当前版本及 Node.js 要求，必要时安装便携运行时，并固定本次使用的启动器。已有自定义 CLI 时，可在请求中提供其绝对路径，或通过 `MULTIAGENTOR_CLI_PATH` 指定。

### 2. 选择场景并运行

将下面的目标替换为自己的需求：

```text
使用 $multiagentor，查找适合“<你的自动化目标>”的官方场景。
引导我选择场景、浏览器身份和任务参数，展示最终配置，确认后执行到完成。
```

一般会经历以下步骤：

1. **授权 MultiAgentor 账号**：未登录时打开可见 OAuth 流程，由用户在浏览器完成登录和授权。
2. **选择场景**：从服务实际返回的列表中选择，Agent 读取该版本的参数和执行要求。
3. **选择浏览器身份**：复用已有身份、新建独立身份、导入身份包，或向已有身份导入 Cookie。
4. **完成网站登录**：需要时打开可见 MultiAgentBrowser，由用户完成登录、验证码或其他验证。
5. **确认运行配置**：检查场景、身份、代理、参数和可见/headless 模式，再确认运行。
6. **查看结果**：Agent 持续监督到终态，检查业务完成条件，报告状态、任务/运行 ID 以及 `result.json`、截图等证据路径。

首次启动浏览器会下载并校验 MultiAgentBrowser。运行期间保持 Agent 聊天和任务进程可用，人工登录时按提示操作。密码、验证码和 Cookie 值不要发送到聊天中。

### 更多提示词示例

**复用已有浏览器身份：**

```text
使用 $multiagentor，列出已有浏览器身份和可用场景，让我选择后创建并运行任务。
```

**执行已有任务：**

```text
使用 $multiagentor，运行已有任务 <任务 ID>，确认浏览器身份和运行参数后执行到完成，最后给出结果和证据路径。
```

**使用指定的 CLI：**

```text
使用 $multiagentor，固定 CLI 启动器为 <CLI 的绝对路径>，保留这份 CLI 安装，不切换到受管版本。检查能力后引导我运行场景。
```

**显式使用旧 JSONL 模式：**

```text
使用 $multiagentor，这次显式选择旧 JSONL 前台执行模式。检查兼容性并确认场景、浏览器身份和参数后，监督任务到终态。
```

## 更新与常见问题

### Skill 和 CLI 如何更新？

默认工作流会检查 Skill 和受管 CLI 的更新。Skill 有新版时会替换整个安装目录，并要求新建聊天以加载新指令；CLI 更新在没有活动浏览器 Run 时进行。显式指定的 CLI 启动器和项目锁定版本会按 Skill 规则保留。

只想检查更新时，可以从本仓库根目录手动运行以下命令。它们需要联网，不替换 Skill 或 CLI：

**Windows PowerShell：**

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\skills\multiagentor\scripts\update-skill.ps1 -CheckOnly
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\skills\multiagentor\scripts\update-cli.ps1 -CheckOnly
```

**macOS Terminal：**

```bash
bash ./skills/multiagentor/scripts/update-skill.sh --check-only
bash ./skills/multiagentor/scripts/update-cli.sh --check-only
```

上述命令检查当前仓库副本的 Skill 和受管 CLI。检查已安装的 Skill 时，将 `update-skill` 的脚本路径换为实际安装目录中的对应路径。

Skill 版本只记录在 [SKILL.md](skills/multiagentor/SKILL.md) 的 `metadata.version` 中，CLI 版本单独管理。

### 找不到 Skill 或加载了旧版本

检查实际路径是否为 `<Skill 发现目录>/multiagentor/SKILL.md`，并确认复制了完整文件夹。新建聊天，必要时重启 Codex；如果仍加载旧版本，让 Agent 报告实际读取路径，排查其他安装目录中的同名副本。

### 提示 `UNSUPPORTED_HOST` 或 `UNSUPPORTED_WORKER_SESSION`

前者表示宿主缺少所需独立子 Agent 能力，后者表示当前 CLI 缺少 worker 命令。默认模式会停止；检查宿主能力和固定的 CLI 版本，或在适用时显式请求旧 JSONL 模式。详细说明见 [worker 执行要求](skills/multiagentor/references/worker-execution.md)。

### 登录或下载失败

MultiAgentor 账号授权与目标网站登录是两个流程，见 [认证说明](skills/multiagentor/references/authentication.md)。安装或下载失败时，先检查网络、代理和当前平台是否受支持，再参照 [安装说明](skills/multiagentor/references/installation.md) 与 [故障排查](skills/multiagentor/references/troubleshooting.md)。

## 主要能力

- 检查 Windows x64 或 Apple Silicon macOS 环境。
- 在没有 Node.js 的机器上下载并校验便携 Node.js 运行时。
- 从 npm registry 获取当前 CLI 包及 Node 版本要求并完成安装。
- 检查 Skill、本地 CLI 和 npm 最新版本；发现新版时覆盖旧 Skill 或受管 CLI。
- 动态读取 CLI 帮助、返回 JSON、场景定义和运行协议，适应接口变化。
- 完成登录、场景选择、浏览器身份准备、任务创建和前台执行。
- 为 MultiAgentor 账号打开可见 OAuth 授权流程，并将网站账号登录限制在可见的持久化 MultiAgentBrowser 中。
- 每次运行场景前进行引导式选择：复用身份、新建养号身份、导入身份包或导入 Cookie，再确认任务参数与运行模式。
- 新建浏览器身份时只需填写名称和可选代理；系统与浏览器指纹由 Skill 自动检测。
- Codex 默认通过 `--worker-session` 使用主 Agent 与不继承聊天历史的新子 Agent，按业务步骤监督至终态。
- 每个动作等待执行与有界完成检查，返回最新页面观察；完全相同的观察返回引用映射，减少重复正文。
- 保留显式选择的旧 JSONL 运行方式，并读取运行结果和证据。
- 处理代理、Cookie、浏览器包、运行取消、故障诊断和工作区迁移。

## 目录

```text
skills/multiagentor/
├── SKILL.md
├── agents/
├── evals/
├── references/
└── scripts/
```

详细执行规则以 [SKILL.md](skills/multiagentor/SKILL.md) 为入口；安装、登录、引导流程和故障处理的参考文档位于 `references/`，辅助脚本位于 `scripts/`。

## 新模式与本地手测

新模式要求宿主支持 `spawn_agent` 的 `fork_turns="none"`，CLI 帮助包含全部 worker 命令。缺失时明确停止，不静默降级。主 Agent 管理 Run、预算和进度，子 Agent 观察与操作页面并只回传摘要；最终关闭由主 Agent 执行。

本地测试明确指定 Skill 副本及 CLI 启动器时，保留该版本，跳过会替换它们的自动更新。读取 [手动测试说明](tests/manual-worker.md)。当前无子命令本地 JSONL 入口尚未支持 worker 模式；场景工厂的旧本地成功证据不能证明新模式。

## Task reuse and memory

The default entry reuses a uniquely matching task before asking for identity creation or unchanged parameters. Supplied configuration conflicts require explicit consent. Task-memory scenarios use the CLI revision API described in [task-memory.md](skills/multiagentor/references/task-memory.md). Engineering progress is tracked in [local Issues](docs/issues/README.md).
