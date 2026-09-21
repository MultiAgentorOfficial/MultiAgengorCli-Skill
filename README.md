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
- 监督 JSONL 浏览器会话至终态，并读取运行结果和证据。
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
