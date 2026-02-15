# Superkit MCP Handoff Document

## Status & Sequence

Superkit is being **mothballed** after its content is imported into the MCP repo. The sequence:

1. **This document** describes what content exists, its format, what's broken, and how to expose it via MCP
2. **MCP repo session** uses this doc to build tools/resources, pulling content from the superkit repo
3. **Future session** mothballs superkit (gut deprecated files, rewrite README)

Do not delete superkit content until the MCP repo has imported everything it needs.

---

## Content Inventory

### Grok Patterns (`bin/skgrok.jsup`)

90 patterns in SUP format (SuperDB's native data format). Each record has two fields:
- `pattern_name` (string) - e.g. `"USER"`, `"IP"`, `"TIMESTAMP_ISO8601"`
- `regex` (string) - the regex pattern

Categories covered: user/email, numbers (int, float, hex), network (IP, hostname, port, URI),
datetime (multiple timestamp formats), paths (Unix, Windows), log formats (syslog, httpd,
combinedapachelog), and general-purpose (word, space, greedydata, quotedstring).

**Original tool**: `bin/skgrok` was an fzf-based interactive browser that let users search
and preview patterns in the terminal.

**MCP suggestion**: Expose as a resource (structured data) plus a search tool that filters
patterns by name or regex content. The search tool replaces the interactive fzf browser.

---

### Tutorial Docs (`doc/*.md`)

Each file is a standalone tutorial/guide in Markdown. Quality and completeness varies.

| File | Topic | mdtest | Notes |
|------|-------|--------|-------|
| `grok.md` | Practical grok() tutorial | Yes (14) | Capture patterns, inline regex, gotchas |
| `subqueries.md` | Correlated subqueries | Yes (23) | SQL, derived table, piped, join approaches |
| `unnest.md` | Unnest operator deep-dive | Yes (8) | Includes `unnest ... into` form |
| `tutorial/chess-tiebreaks.md` | Real-world showcase | Yes (9) | PGN parsing, grok, unnest, live API integration |
| `joins.md` | Outer join patterns | Yes (12) | Left, right, anti, full; **full outer join bug in 0.1.0** |
| `from.md` | Dynamic `from` expressions | Yes (22) | **BROKEN in 0.1.0** - historical interest only |
| `sup_to_bash.md` | SuperDB-to-bash extraction | No | Shell-focused, no mdtest blocks |
| `super_db_update.md` | Lake update workaround | No | No native update yet (upstream issue #4024) |
| `moar_subqueries.md` | Subquery performance notes | No | File re-reading overhead analysis |
| `user_func_op.md` | User functions and ops | No | **Stub only** - skip |

#### mdtest integration

Six of the tutorial docs use **mdtest**, the doc-testing tool built into the
[brimdata/super](https://github.com/brimdata/super) repo. Code examples are written as
fenced blocks with `mdtest-command` and `mdtest-output` language tags:

    ```mdtest-command
    super -s -c 'values 1 + 2'
    ```
    ```mdtest-output
    3
    ```

`mdtest` runs each `mdtest-command` block as a shell command and asserts its stdout matches
the following `mdtest-output` block. This catches docs that fall out of date when SuperDB
syntax or behavior changes.

**Goal**: Preserve the mdtest blocks in imported docs so they can be run against future
SuperDB releases to catch breakage. The MCP repo should be able to run `mdtest` from the
super repo against its doc files (either by pointing mdtest at a directory, or via CI).

**MCP suggestion**: Expose docs as resources (one per doc) and/or a search tool that searches
across doc content. Consider tagging by topic for discoverability. Keep mdtest blocks intact
in the source files so they remain testable.

---

### Recipe Functions (`src/*.spq`)

Custom SuperDB functions and operators. Each file contains one or more `fn`/`op` definitions
with `skdoc_*` metadata calls (description, examples). The `skdoc_*` calls are no-ops at
runtime and can be stripped for MCP presentation.

| File | Functions/Ops | Description |
|------|--------------|-------------|
| `array.spq` | `sk_in_array` (fn), `sk_array_flatten` (op) | Array membership test, nested array flattening |
| `format.spq` | `sk_format_bytes` (fn) | Human-readable byte sizes (KB, MB, GB, etc.) |
| `integer.spq` | `sk_clamp`, `sk_min`, `sk_max` (fn) | Numeric clamping and min/max |
| `records.spq` | `sk_keys` (op), `sk_merge_records` (op), `sk_add_ids` (op) | Record introspection, merging, ID generation |
| `string.spq` | `sk_slice`, `sk_capitalize`, `sk_titleize`, `sk_pad_left`, `sk_pad_right` (fn), `sk_urldecode` (op) | String manipulation utilities |

**Skip these**:
- `include.spq` - BROKEN in 0.1.0 (relies on dynamic file expressions)
- `version.spq` - just returns `"0.2.2"`, no value for MCP

**MCP suggestion**: Expose as a searchable function reference (tool or resource). Could parse
the `skdoc_*` metadata to extract descriptions and examples, or just present the raw `.spq`
source. The functions themselves can be copy-pasted into user queries.

---

### Test Examples (`test/*.bats`)

85 tests across 5 files using the bats test framework:
- `test/array.bats`
- `test/format.bats`
- `test/integer.bats`
- `test/records.bats`
- `test/string.bats`

Tests demonstrate usage patterns, edge cases, and SuperDB quirks. They use a helper
(`test/test_helper.bash`) with `sk_run`/`sk_assert` helpers that invoke `super` with
the library files auto-included.

**MCP suggestion**: Mine as usage examples. Each test case is a concise "how to use X"
that can supplement function reference docs.

---

## What NOT to Import

Already available through MCP or obsolete:

| Item | Reason |
|------|--------|
| `doc/superdb-expert.md` | Served by MCP `super_help` topic `"expert"` |
| `doc/zq-to-super-upgrades.md` | Served by MCP `super_help` topic `"upgrade"` |
| All CLI tools (`bin/sk`, `bin/skdoc`, `bin/skops`) | Superseded by MCP LSP tools |
| Build/install/release infra (`build`, `install.sh`, `release.sh`, `dist/`) | Distribution model obsolete |
| `src/skdoc.spq` | Metadata parser for the defunct `skops` tool |
| `util/`, `mdtest/`, `img/` | Setup helpers, doc testing, screenshots |
| `src/*-test.sh` | Old shell tests, replaced by bats suite |

---

## Known Issues in SuperDB 0.1.0

These affect some content and should be noted when importing:

- **Dynamic file expressions broken**: `from (expr)` syntax doesn't work. Affects `include.spq` and `from.md`.
- **Full outer join bug**: `full outer join` produces incorrect results in some cases. Noted in `joins.md`.
- **`map()` doesn't accept user-defined functions**: Use lateral subqueries instead.
- **No native lake update**: Workaround documented in `super_db_update.md` (upstream issue #4024).
- **`fn` is a keyword**: Can't use `fn` as a variable name.
