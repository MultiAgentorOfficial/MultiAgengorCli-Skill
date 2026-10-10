# Historical worker compatibility

Worker CLI commands remain available for existing integrations, but the MultiAgentor Skill no longer executes scenarios through child Agents or step leases. Use [supervised-execution.md](supervised-execution.md) for all new runs. Do not request spawn_agent or worker host capabilities. Historical worker evidence is not proof of main-Agent JSONL acceptance.

Existing worker consumers must inspect their pinned CLI contract. The current implementation returns one immediate post-action observation without the old 300ms/1500ms stabilization loop. Explicit completion conditions remain bounded and distinct from business success.
