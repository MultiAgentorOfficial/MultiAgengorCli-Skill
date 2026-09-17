# MultiAgentor Skill

这是与 `multiagentor-scenario-cli` 当前 V2 命令和 JSONL 浏览器协议配套的独立 Codex Skill 仓库。流程组织参考 [MultiAgentor 官方公开 Skill](https://github.com/MultiAgentorOfficial/MultiAgentorCLISkills)，但 CLI 事实只取自当前 `multiagengorcli` 仓库、实际二进制帮助和实时返回数据。

## 安装

可使用 `$skill-installer` 从本仓库的 `skills/multiagentor` 子目录安装。手工安装时，只复制 [skills/multiagentor](skills/multiagentor/) 到 `$CODEX_HOME/skills/multiagentor`（未设置 `CODEX_HOME` 时通常为 `~/.codex/skills/multiagentor`），然后新建 Codex 任务加载 Skill。

重新开启 Codex 任务后，可直接描述 MultiAgentor 操作，或显式使用 `$multiagentor`。

Skill 版本只记录在 `skills/multiagentor/SKILL.md` 的 `metadata.version` 中，不维护第二份版本文件。

CLI 需要单独安装。Skill 会先查找用户给出的路径、`MULTIAGENTOR_CLI_PATH`、PATH 中的 `multiagentor`，以及本地 CLI 仓库构建产物。CLI 源码仓库：

```text
https://gitlab.kuajingvs.com/com-bifang-workspace/multiagengorcli
```

## 能力

- 安装、定位和验证 CLI。
- 登录服务、搜索和下载官方场景。
- 创建和维护持久浏览器身份、代理、Cookie 与浏览器包。
- 创建、修改和删除任务。
- 在当前 Agent 会话中通过 JSONL 监督浏览器运行至终态。
- 查询日志和证据、取消运行、诊断故障和迁移工作区。

入口说明位于 [SKILL.md](skills/multiagentor/SKILL.md)，安装、版本检查、执行流程与故障排查按需存放在 [references](skills/multiagentor/references/) 中。
