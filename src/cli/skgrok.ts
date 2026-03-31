#!/usr/bin/env node

import { superGrokPatterns } from '../lib/grok.js';
import { pager } from './pager.js';

const query = process.argv[2];
const result = superGrokPatterns(query);

if (!result.success) {
  console.error(result.error);
  process.exit(1);
}

if (result.count === 0) {
  console.error(query ? `No grok patterns matching "${query}"` : 'No grok patterns found');
  process.exit(1);
}

const maxName = Math.max(...result.patterns.map(p => p.pattern_name.length));
const lines = result.patterns.map(p => {
  const name = p.pattern_name.padEnd(maxName + 2);
  const regex = p.regex.length > 80 ? p.regex.slice(0, 77) + '...' : p.regex;
  return `${name}${regex}`;
});

pager(lines.join('\n') + '\n');
