#!/usr/bin/env node

import { superRecipes } from '../lib/recipes.js';
import { pager } from './pager.js';

const query = process.argv[2];
const result = superRecipes(query);

if (!result.success) {
  console.error(result.error);
  process.exit(1);
}

if (result.count === 0) {
  console.error(query ? `No recipes matching "${query}"` : 'No recipes found');
  process.exit(1);
}

const lines: string[] = [];
for (const r of result.recipes) {
  const argStr = r.args.length > 0
    ? r.args.map(a => a.name).join(', ')
    : '';
  const sig = r.type === 'op'
    ? `op ${r.name} ${argStr}`
    : `${r.name}(${argStr})`;

  lines.push(`${sig}`);
  lines.push(`  ${r.description}`);

  if (r.examples.length > 0) {
    for (const ex of r.examples) {
      lines.push(`  ${ex.i} => ${ex.o}`);
    }
  }
  lines.push('');
}

pager(lines.join('\n'));
