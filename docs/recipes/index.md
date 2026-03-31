---
title: Recipes
layout: default
has_children: true
nav_order: 5
---

# Recipes

Reusable SuperSQL functions and operators for common tasks. Include them in your
queries with `from` or `-I`:

```supersql
from 'string.spq' | values sk_capitalize('hello')
```

```bash
super -I string.spq -c "values sk_capitalize('hello')"
```

Recipe source files are available in the
[superkit](https://github.com/chrismo/superkit/tree/main/docs/recipes)
repository.
