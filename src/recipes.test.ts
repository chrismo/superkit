import { describe, it, expect } from 'vitest';
import { execFileSync } from 'child_process';
import { readFileSync, readdirSync } from 'fs';
import { join } from 'path';
import { superRecipes } from './lib/recipes.js';

const recipesDir = join(import.meta.dirname, '..', 'docs', 'recipes');

// Load all .spq files and strip skdoc blocks — they contain nested
// brackets in example fields that super can't parse as valid syntax.
// Keep only the actual fn/op implementations.
const allSpqFiles = readdirSync(recipesDir)
  .filter(f => f.endsWith('.spq'))
  .sort();

// Strip skdoc blocks and functions that can't be parsed by super -I
// (sk_shell_quote has nested quotes in f-strings that break the file parser)
const UNPARSEABLE_FNS = [
  'sk_shell_quote',  // nested quotes in f-string
  'sk_merge_records', // string literal with braces
  'sk_chr',          // uses `let` keyword (broken in current super)
  'sk_alpha',        // depends on sk_chr
  'sk_seq',          // depends on sk_chr (via sk_pad_left, but also broken)
  'sk_add_ids',      // uses `that` (old syntax for `this`)
];

function stripSkdocBlocks(content: string): string {
  const lines = content.split('\n');
  const result: string[] = [];
  let inSkdoc = false;
  let inUnparseable = false;
  let skipNextClosingParen = false;
  let parenDepth = 0;

  for (const line of lines) {
    // Strip skdoc metadata blocks
    if (!inSkdoc && !inUnparseable && /^(?:fn|op)\s+skdoc_/.test(line)) {
      inSkdoc = true;
      continue;
    }

    if (inSkdoc) {
      if (line.includes('<skdoc>)')) {
        inSkdoc = false;
        skipNextClosingParen = true;
      }
      continue;
    }

    if (skipNextClosingParen) {
      if (line.trim() === '') {
        result.push(line);
        continue;
      }
      if (line.trim() === ')') {
        skipNextClosingParen = false;
        continue;
      }
      skipNextClosingParen = false;
    }

    // Strip functions that cause parse errors when loaded via -I
    if (!inUnparseable) {
      const fnMatch = line.match(/^(?:fn|op)\s+(\w+)/);
      if (fnMatch && UNPARSEABLE_FNS.includes(fnMatch[1])) {
        inUnparseable = true;
        parenDepth = 0;
        for (const ch of line) {
          if (ch === '(') parenDepth++;
          if (ch === ')') parenDepth--;
        }
        if (parenDepth <= 0) inUnparseable = false;
        continue;
      }
    }

    if (inUnparseable) {
      for (const ch of line) {
        if (ch === '(') parenDepth++;
        if (ch === ')') parenDepth--;
      }
      if (parenDepth <= 0) inUnparseable = false;
      continue;
    }

    result.push(line);
  }

  return result.join('\n');
}

import { writeFileSync } from 'fs';
import { tmpdir } from 'os';

const allDefinitions = allSpqFiles
  .map(f => stripSkdocBlocks(readFileSync(join(recipesDir, f), 'utf-8')))
  .join('\n');

function normalizeOutput(s: string): string {
  return s
    .replace(/^'(.*)'$/, '"$1"')
    .trim();
}

// Write stripped defs to a file that super can load with -I
const defsFile = join(tmpdir(), 'superkit-test-defs.spq');
writeFileSync(defsFile, allDefinitions);

function runSuper(query: string): string {
  const result = execFileSync('super', ['-I', defsFile, '-s', '-c', query], {
    encoding: 'utf-8',
    timeout: 10_000,
  });
  return result.trim();
}

// Functions stripped from defs that can't be tested
const SKIPPED_FNS = new Set(UNPARSEABLE_FNS);

const { recipes } = superRecipes();

// Skip examples that are prose descriptions, not executable assertions
function isExecutableExample(example: { i: string; o: string }): boolean {
  const nonExecutable = [
    'quoted and wrapped', 'single-quoted', 'tabs replaced',
    'newlines replaced', 'safely embedded', 'properly escaped',
    'single record', 'arbitrary user', 'formatted',
  ];
  return !nonExecutable.some(s => example.o.toLowerCase().includes(s));
}

describe('recipe skdoc examples', () => {
  for (const recipe of recipes) {
    if (SKIPPED_FNS.has(recipe.name)) continue;
    // Skip shell-pattern recipes (type: "shell") — not SuperDB functions
    if (recipe.type === 'shell') continue;

    for (const example of recipe.examples) {
      if (!isExecutableExample(example)) continue;

      it(`${recipe.name}: ${example.i}`, () => {
        // Some examples already include "values", don't double-prefix
        const query = example.i.startsWith('values ')
          ? example.i
          : `values ${example.i}`;
        const actual = runSuper(query);
        const expected = normalizeOutput(example.o);
        // Strip type decorators (e.g., "29::uint8" → "29") for comparison
        const actualClean = actual.replace(/::\w+$/, '');
        expect(actualClean).toBe(expected);
      });
    }
  }
});
