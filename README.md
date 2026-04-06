# SuperKit

Documentation, tutorials, and recipes for [SuperDB](https://superdb.org/).

**Website:** [chrismo.github.io/superkit](https://chrismo.github.io/superkit/)

## Install

```bash
npm install -g @chrismo/superkit
```

## CLI Tools

- `skdoc` — Browse documentation (expert guide, upgrade guide, tutorials)
- `skgrok` — Search grok patterns
- `skops` — Browse recipe functions and operators

Also available via `npx skdoc`, `npx skgrok`, `npx skops`.

## Content

- **Expert Guide** — Comprehensive SuperSQL syntax reference
- **Upgrade Guide** — Migration guide from zq to SuperDB
- **Tutorials** — Step-by-step guides for common patterns
- **Recipes** — Reusable SuperSQL functions and operators
- **Grok Patterns** — All SuperDB grok patterns

## Library

The [SuperDB MCP server](https://github.com/chrismo/superdb-mcp) depends on
this package for its documentation tools. The TypeScript API is available for
other integrations:

```typescript
import { superHelp, superRecipes, superGrokPatterns } from '@chrismo/superkit';
```

## Upgrading from pre-npm SuperKit

If you previously installed SuperKit via the old `install.sh` script, remove
the legacy files:

```bash
rm -f ~/.local/bin/sk ~/.local/bin/skdoc ~/.local/bin/skgrok \
      ~/.local/bin/skgrok.jsup ~/.local/bin/skops \
      ~/.local/bin/skops.jsup ~/.local/bin/skops.spq
```

## License

SuperKit is licensed under the [BSD-3-Clause License](LICENSE.txt).

SuperKit is an independent project that documents and provides recipes for
[SuperDB](https://github.com/brimdata/super), which is licensed under the
[SuperDB Source Available License](https://github.com/brimdata/super/blob/main/LICENSE.md).
SuperKit does not distribute SuperDB source code or binaries.
