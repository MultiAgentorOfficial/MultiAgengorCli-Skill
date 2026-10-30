# MA Skill 2.1.2 release

2026-10-30 用户明确授权提交、推送并发布 Skill 2.1.2。范围为 ISSUE-0007 的监督执行修正：开跑前核对辅助脚本持久化分支，恢复次数和原期限即时保存，记录缺口先按已有证据协调，逐 Run 依据固定场景决定继续或关闭，并保留非敏感 close 请求及依据。已证实协议违规、未知关键状态及真实全局停止条件仍按场景处理。

Skill schema、Markdown 本地链接、UTF-8/换行与差异检查通过；既有 Node 测试 5 项：3 通过、0 失败、2 项因未配置真实 candidate/legacy 启动器跳过。新增 4 项评估提示，未声称它们已获得真实 Agent 执行轨迹。真实账号 30 分钟复测仍由用户另一环境后续完成；发行不代表行为验收通过。

发行包由暂存 Git blobs 生成，保留 multiagentor/ 目录结构，全部 30 个文件与暂存 Skill blobs 逐字节一致。归档：dist/multiagentor-skill-2.1.2.zip；SHA-256：ab5126b793ca11fb1602b8e9b69d733506f132ee31b523ab5d6358dc1f085a38。

不更新 CLI/npm、工厂依赖锁或本机安装，不修改历史 Run/task memory。目标发行：https://github.com/MultiAgentorOfficial/MultiAgengorCli-Skill/releases/tag/v2.1.2 。推送和上传后另行记录远端及下载校验结果。
