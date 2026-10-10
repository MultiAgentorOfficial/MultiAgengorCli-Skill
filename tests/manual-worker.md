> Historical Worker compatibility only. The default is main-Agent local transport; see manual-local.md.

# Historical worker test record

This document is retained for compatibility history. It is not the current Skill acceptance procedure.

## Current acceptance

1. Pin this project Skill and a CLI build with no artificial action delays.
2. Start one task run JSONL process directly in the main Agent.
3. Observe, navigate, scroll, visit a safe detail, dwell explicitly, return and verify current refs.
4. Exercise uncertain response recovery and visible manual-login continuation without resetting deadlines.
5. Close with a truthful status; inspect result/evidence and verify Profile release.
6. Confirm no child Agent or step lease was used; only reading dwell caused explicit waits.

## Previous procedure

# Local Codex worker test

Use a new Codex chat so the replaced global Skill is loaded. Explicitly request this local Skill revision and pin a CLI launcher whose help advertises all worker commands. Skip self-update for this test; an npm release with the same version may lack the feature.

Suggested prompt (replace the launcher and scene/task selection):

> 使用全局 multiagentor Skill 的本地测试版本，跳过 Skill/CLI 自动更新。固定 CLI 启动器为 `<absolute-launcher>`。读取当前帮助，确认独立子 Agent 与 worker 命令后运行选定场景。每个业务步骤使用 `fork_turns="none"`，主 Agent 不读取页面快照。至少执行三个业务步骤，正常动作后消费返回观察，不重复请求快照。遇到登录/验证返回主 Agent 等待人工处理。结束后报告业务结果、step/observe/full/unchanged/internal-sample/response-byte 指标；Token 计量覆盖所有子会话，否则说明范围。

Check the following from real host/run evidence:

- All three children have no inherited parent chat history, and only summaries return to main.
- One owner process/browser/Profile remains across steps; each child's first observation is full.
- An unchanged-page repeat emits unchanged/refMap without repeated body. Changed state emits full. No normal action requires a separate snapshot request.
- A condition timeout or post-action observation failure does not replay a completed action. Stale refs cause recovery observe.
- Login returns needs-user, main revokes the lease, user completes it in the visible browser, and a new child resumes within the original budgets.
- Only main finishes; result status matches the business condition, owner exits and Profile is released.
- Record actual CLI build/package provenance, Skill/scenario versions and evidence paths. Main-only Token usage is not the combined total.

Scene changes in the factory are local until explicitly uploaded. A service task downloads its service version, not the factory working copy; inspect the pinned version/content before claiming the revised package was tested. Upload is a separate authorized operation.

The factory's no-subcommand local JSONL path currently cannot run worker mode. Its legacy acceptance remains useful for business rules but does not meet this test's worker criteria.
