# MA Skill 2.0.2 release

2026-10-28 用户明确授权三个仓库提交推送、发布并更新本地 CLI/Skill。维护源提交 `2a1c0a4f0b1599ae90ff19a6aa31c4ed8ba5b115` 及注解标签 `v2.0.2` 已推送，远程 main/tag 解引用一致。

GitHub Release: https://github.com/MultiAgentorOfficial/MultiAgengorCli-Skill/releases/tag/v2.0.2

`dist/multiagentor-skill-2.0.2.zip` 包含25个文件，与标签 Git blobs 逐字节一致。独立下载发布资产后 SHA-256 相同：`a044561387dba331fcfae93dd5c2357707ac02cdefc3692922552239308b37d1`。Skill schema 校验通过；实际 CLI0.4.3 安装候选发现回归1项通过、legacy1项条件跳过。

规则要求所有 MA 场景页面观察与操作仅使用 MA CLI；浏览器内部实现不受此限制。该规则是 Agent 指令和调用轨迹边界，不代表 CLI 已强制隔离宿主其他工具。reveal 仅在需要滚入后观察时使用，按能力发现阻止旧 CLI 使用新动作。

工厂项目依赖已锁定官方 v2.0.2 源提交。用户级安装使用官方 updater 的 v2.0.2 固定标签，在本次其他发布操作完成后执行；安装后需新建聊天加载新指令。不运行真实 X 账号或以发布代替场景性能验收。
