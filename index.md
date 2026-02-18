---
title: Home
layout: default
nav_order: 1
---

# SuperKit

Documentation, tutorials, and recipes for [SuperDB](https://superdb.org/).

## Guides

- [Expert Guide]({% link expert-guide.md %}) — Comprehensive SuperSQL syntax reference covering data types, operators, expressions, aggregations, and more.
- [Upgrade Guide]({% link upgrade-guide.md %}) — Migration guide for upgrading from zq to SuperDB, with all breaking changes documented.

## Tutorials

Step-by-step tutorials covering common SuperDB patterns:

{% assign tutorials = site.pages | where_exp: "page", "page.parent == 'Tutorials'" | sort: "nav_order" %}
{% for tutorial in tutorials %}
- [{{ tutorial.title }}]({{ tutorial.url | relative_url }})
{% endfor %}

---

Content is auto-synced from [superdb-mcp](https://github.com/chrismo/superdb-mcp), which serves this material through the SuperDB MCP server for use with coding agents.
