---
nav_exclude: true
---

# TODO

## Consider reviving SuperKit as a CLI install

There's a persistent preference for CLIs over MCPs in the broader community
(e.g. Simon Willison's [Feb 2026 post](https://x.com/simonw/status/2023912875304382725)).
Not everyone is using MCP-capable tools, and a standalone CLI would make the
docs, recipes, and grok patterns accessible without an MCP client.

Why both CLI and MCP:
- In my limited experience, MCP is superior for agent workflows with SuperDB
  specifically — Claude does WAY better with the SuperDB MCP than a shell script
- But most folks report better success with CLIs over MCPs in practice — not everyone
  is using MCP-capable tools
- Token cost is the strongest argument for CLI (no round-trips through the model)
- No reason not to provide both

Possible approach:
- Sync the MCP's own scripts (help, recipes, grok) into superkit so both delivery
  mechanisms share the same underlying content
- `sk help expert` / `sk help tutorial:grok` — same content as `super_help`
- `sk grok <pattern>` — search grok patterns
- `sk recipes <query>` — browse recipe functions
- Installable via Homebrew, npm, or standalone binary
- Content authored in superdb-mcp, scripts synced here, CLI wraps them
