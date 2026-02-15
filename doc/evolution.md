# Superkit Evolution: From Installable Library to MCP Content Source

## Context

Superkit was built as a distributable SuperDB function library with CLI tools (sk, skdoc, skops, skgrok). With the SuperDB MCP server now providing LSP-powered docs, completions, and query execution, plus coding agents as the primary consumer, the CLI tools and installable library model no longer make sense. The value is in the **content** (recipes, patterns, educational material), not the delivery mechanism.

## What Changes

### Deprecated (slated for removal)

- `bin/sk` - auto-include wrapper, had performance issues with larger files
- `bin/skdoc` - terminal doc browser, superseded by MCP `super_docs` + `super_help`
- `bin/skops`, `bin/skops.spq`, `bin/skops.jsup` - terminal function reference, superseded by MCP LSP tools
- `install.sh`, `uninstall.sh`, `release.sh`, `dist/` - distribution infra
- `util/` - docker/ubuntu setup, installer helpers
- `mdtest/`, `test-doc.sh` - Go-based doc testing
- `img/` - README screenshot
- `src/*-test.sh` - shell test scripts (tests live in test/*.bats)
- `src/skdoc.spq` - metadata parser for skops
- `build` script - mostly doc-parsing and release packaging
- `doc/superdb-expert.md`, `doc/zq-to-super-upgrades.md` - already served by MCP `super_help`

### Keep & Reorganize

- `src/*.spq` - custom functions, reframed as **recipes/patterns** for MCP consumption
- `doc/*.md` - educational materials (subqueries, joins, etc.), reframed as MCP content
- `bin/skgrok.jsup` - grok pattern data, becomes MCP content
- `test/*.bats` - tests validate the recipes work; also serve as usage examples
- `test/test_helper.bash` - test infrastructure

### Keep unchanged for now

- `changelog.jsup` - history
- `README.md` - will need rewrite eventually, but not in this pass
- `LICENSE.txt`, `.gitignore` - standard repo files

## MCP Content Inventory

What's available for building MCP tools/resources:

1. **Recipe functions** (`src/*.spq`) - custom SuperDB functions with docs and examples
2. **Educational docs** (`doc/*.md`) - guides on subqueries, joins, patterns
3. **Grok patterns** (`bin/skgrok.jsup`) - all SuperDB grok patterns in structured format
4. **Test examples** (`test/*.bats`) - working examples of SuperDB usage patterns
