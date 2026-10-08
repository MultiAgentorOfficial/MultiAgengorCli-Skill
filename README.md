# MultiAgentor CLI Skill

这是面向 `multiagentor-scenario-cli` 的独立 Agent Skill。

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

安装时将 `skills/multiagentor` 目录复制到 Codex 的 `skills/multiagentor` 目录，然后新建任务加载 Skill。

Skill 版本只记录在 `SKILL.md` 的 `metadata.version` 中。

## 新模式与本地手测

新模式要求宿主支持 `spawn_agent` 的 `fork_turns="none"`，CLI 帮助包含全部 worker 命令。缺失时明确停止，不静默降级。主 Agent 管理 Run、预算和进度，子 Agent 观察与操作页面并只回传摘要；最终关闭由主 Agent 执行。

本地测试明确指定 Skill 副本及 CLI 启动器时，保留该版本，跳过会替换它们的自动更新。读取 [手动测试说明](tests/manual-worker.md)。当前无子命令本地 JSONL 入口尚未支持 worker 模式；场景工厂的旧本地成功证据不能证明新模式。
