# Sync zq-to-super Upgrade Guide

Update `doc/zq-to-super-upgrades.md` with breaking changes from brimdata/super since the document was last updated.

**This command runs autonomously. No user confirmation required.**

## Execution Plan

### Phase 1: Determine Last Sync Date

Read `doc/zq-to-super-upgrades.md` and extract the date from the header (format: "Jan 5, 2026 — SuperDB Version X.XXXXX").

Convert to ISO format for GitHub API queries.

### Phase 2: Fetch Recent Commits

Use WebFetch to get commits since last sync:
- `https://api.github.com/repos/brimdata/super/commits?since=<last-sync-date>&per_page=100`

If there are more than 100 commits, paginate to get all of them.

### Phase 3: Identify Breaking Changes

Review commit messages and look for:
- Keywords: "breaking", "rename", "remove", "deprecate", "change", "syntax"
- PR references (fetch PR descriptions for more context)
- Changes to `compiler/parser/parser.peg`
- Changes to function registrations

For each potentially breaking change, fetch the full commit or PR details to understand:
- What changed (old vs new syntax)
- When it changed (date and PR number)
- Why it changed (rationale for the doc)

### Phase 4: Categorize Changes

Sort identified changes into the document's existing categories:
- **CLI Changes** - command-line switches, flags
- **Simple Renames** - keyword/function name changes
- **Behavioral Changes** - syntax or semantic changes
- **Removed Features** - deprecated/removed functionality
- **Type Changes** - return type changes
- **Advanced/Lake Features** - database-specific features

### Phase 5: Update Document

For each new breaking change:

1. Add to the appropriate section following the existing format:
   - Section header with PR/commit link and date
   - Brief explanation of the change
   - `**OLD:**` / `**NEW:**` code blocks where applicable
   - Use `-- comment` style in examples
   - Show expected output for NEW examples

2. Update the Quick Reference table if the change is a simple rename/replacement

3. Update the document date in the header

### Phase 6: Verify Examples

Test NEW examples with the latest available super version:
```bash
ASDF_SUPERDB_VERSION=<latest> super -s -c "<example>"
```

**Note:** The asdf plugin may not have a version string ready for the latest commits.
Check available versions with `asdf list superdb`. If the needed version isn't available:
- Use a `ref:<short-sha>` format: `ASDF_SUPERDB_VERSION=ref:abc1234 super ...`
- Or install a specific commit: `asdf install superdb ref:<commit-sha>`

Fix any examples that don't produce the expected output.

### Phase 7: Update Version

Update the header with:
- Current date
- Latest SuperDB version from asdf (`asdf list superdb | tail -1`)

### Phase 8: Commit and Push

If changes were made:
```bash
git add doc/zq-to-super-upgrades.md
git commit -m "Sync upgrade guide with brimdata/super

Added:
- [list new breaking changes]

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
git push
```

### Phase 9: Report

Summarize what was done:
- Number of new breaking changes found
- Categories updated
- Examples verified
- New document date/version

## Notes

- The upgrade guide is for AI assistants performing automated upgrades
- Follow the "Formatting Conventions for AI Upgraders" section at the end of the doc
- Use double quotes for shell query strings
- Place `-c` last among switches
- All examples should show output
