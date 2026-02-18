# TODO

## Consider reviving SuperKit as a CLI install

There's a persistent preference for CLIs over MCPs in the broader community
(e.g. Simon Willison's [Feb 2026 post](https://x.com/simonw/status/2023912875304382725)).
Not everyone is using MCP-capable tools, and a standalone CLI would make the
docs, recipes, and grok patterns accessible without an MCP client.

Possible scope:
- `sk help expert` / `sk help tutorial:grok` — same content as `super_help`
- `sk grok <pattern>` — search grok patterns
- `sk recipes <query>` — browse recipe functions
- Installable via Homebrew, npm, or standalone binary
- Content still authored in superdb-mcp, synced here, CLI reads from local copy
