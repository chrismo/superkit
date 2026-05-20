# CLI–MCP Parity

Mirror the full SuperDB MCP tool surface as CLI commands, so coding agents
(and humans) can use SuperKit without an MCP client.

## Current state

Content/docs CLIs already exist and work:

| MCP tool             | CLI       | Status |
|----------------------|-----------|--------|
| `super_help`         | `skdoc`   | done   |
| `super_grok_patterns`| `skgrok`  | done   |
| `super_recipes`      | `skops`   | done   |

## Remaining: query & execution CLIs

These MCP tools have no CLI equivalent yet:

| MCP tool             | Proposed CLI              | Notes |
|----------------------|---------------------------|-------|
| `super_query`        | `sk query`                | Core — run a SuperSQL query on files/inline data |
| `super_schema`       | `sk schema`               | Inspect data file shapes/types |
| `super_info`         | `sk info`                 | Version, env, LSP availability |
| `super_db_list`      | `sk db list`              | List pools in a lake |
| `super_db_create_pool`| `sk db create`           | Create a new pool |
| `super_db_load`      | `sk db load`              | Load data into a pool |
| `super_db_query`     | `sk db query`             | Query a pool |
| `super_test_compat`  | `sk test-compat`          | Test query across SuperDB versions |

### Questionable for CLI

These MCP tools are LSP-powered and position-based — they make sense for
editor/agent integrations but may not translate well to a CLI:

| MCP tool             | Notes |
|----------------------|-------|
| `super_complete`     | Completions at cursor position — useful for agents, awkward as CLI |
| `super_docs`         | Symbol docs at cursor position — same concern |
| `super_lsp_status`   | Could fold into `sk info` |

## Dispatcher: `sk` command

Add a `superkit` bin entry (aliased as `sk`) that acts as a subcommand
dispatcher. This also fixes `npx @chrismo/superkit` (currently broken —
no bin matches the package name).

```
sk help          → skdoc
sk grok          → skgrok
sk recipes       → skops
sk query         → new
sk schema        → new
sk info          → new
sk db <sub>      → new
sk test-compat   → new
```

## Open questions

- Should `skdoc`/`skgrok`/`skops` remain as standalone bins, or only
  accessible as `sk help`/`sk grok`/`sk recipes`?
- Where does the `super` binary invocation live? The MCP server has its
  own logic for finding/versioning the binary — does superkit share that
  code, depend on superdb-mcp, or just shell out to `super` on PATH?
- Inline data via stdin (`echo '...' | sk query '...'`) — support it?
- Output format flag (`--format json|sup|csv|table`) across all query commands?
