# Workflow map

Use this map when the requested lifecycle branch is unclear. Each reference owns its decisions; this map adds no second execution recipe.

| Branch | Read | Ready or complete when |
| --- | --- | --- |
| Install, update or broken launcher | [Installation](installation.md) | Intended installation is verified while idle |
| Discover commands or changed binary | [Contract discovery](dynamic-discovery.md) | Pinned contract and required capability domains validated |
| Select/reuse/create/change task or identity | [Guided workflow](guided-workflow.md) | Task binding and effective configuration resolved |
| Service OAuth or website login | [Authentication](authentication.md) | Actual account/page evidence confirms continuation |
| Cross-Run state | [Task memory](task-memory.md) | Capability, source/binding and pending state reconciled |
| Start, drive, recover or close a Run | [Supervised execution](supervised-execution.md) | Business outcome and terminal cleanup verified |
| Scoped/delta/cached observation | [Efficient observation](efficient-observation.md) | Complete relevant evidence and current refs available |
| Permitted unknown visual navigation state | [Visual verification](visual-verification.md) | Current pixels support true/false, otherwise unknown retained |
| Diagnose failure or migrate workspace | [Troubleshooting](troubleshooting.md) | Concrete cause/recovery result or explicit remaining blocker |

Factory drafts use the unpublished-scenario branch in supervised execution. Real task-memory acceptance requires a Workspace Task. Publication is separate from running a local candidate.
