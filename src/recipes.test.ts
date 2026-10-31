import { describe, it, expect } from 'vitest';
import { execFile } from 'child_process';
import { promisify } from 'util';

const execFileAsync = promisify(execFile);
import { readFileSync, readdirSync } from 'fs';
import { join } from 'path';
import { superRecipes, parseSkdoc } from './lib/recipes.js';

const recipesDir = join(import.meta.dirname, '..', 'docs', 'recipes');

// Load all .spq files and strip skdoc blocks — they contain nested
// brackets in example fields that super can't parse as valid syntax.
// Keep only the actual fn/op implementations.
const allSpqFiles = readdirSync(recipesDir)
  .filter(f => f.endsWith('.spq'))
  .sort();

// Strip functions this harness cannot load or assert on.
// Note: a missing comma used to make most recipe files unparseable by
// `super -I`; several entries that lived here were symptoms of that, not
// broken functions. Verify against the real file before adding to this list.
const UNPARSEABLE_FNS = [
  'sk_chr',          // uses `let` keyword (broken in current super)
  'sk_alpha',        // depends on sk_chr
];

// Parseable, but this harness wraps every example in `values ...`, which
// cannot represent an op that yields multiple values. Excluded from
// assertions only — their definitions still load.
const MULTI_VALUE_OPS = ['sk_seq'];

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
      if (line.includes('<skdoc>)') || line.includes('"skdoc")')) {
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

// Write stripped defs to a file that super can load with -I.
// The filename is per-process: vitest also picks up the compiled copy of this
// suite under dist/, and two runners sharing one path tear the file mid-write
// whenever their contents differ (i.e. whenever dist/ is stale).
const defsFile = join(tmpdir(), `superkit-test-defs-${process.pid}.spq`);
writeFileSync(defsFile, allDefinitions);

async function runSuper(query: string): Promise<string> {
  const { stdout } = await execFileAsync('super', ['-I', defsFile, '-s', '-c', query], {
    encoding: 'utf-8',
    timeout: 10_000,
  });
  return stdout.trim();
}

// Functions with no assertable examples: those stripped from the defs file,
// plus ops whose output this harness cannot express.
const SKIPPED_FNS = new Set([...UNPARSEABLE_FNS, ...MULTI_VALUE_OPS]);

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

// Expected outputs in skdoc examples are written loosely (single-quoted
// strings, extra spaces). Let super canonicalize them so the comparison is
// exact; fall back to light normalization for anything super can't parse.
async function canonicalExpected(o: string): Promise<string> {
  try {
    return await runSuper(`values ${o}`);
  } catch {
    return normalizeOutput(o);
  }
}

// Each example spawns super, so run them concurrently.
describe.concurrent('recipe skdoc examples', () => {
  for (const recipe of recipes) {
    if (SKIPPED_FNS.has(recipe.name)) continue;
    // Skip shell-pattern recipes (type: "shell") — not SuperDB functions
    if (recipe.type === 'shell') continue;

    for (const example of recipe.examples) {
      if (!isExecutableExample(example)) continue;

      it(`${recipe.name}: ${example.i}`, async ({ expect }) => {
        // Some examples already include "values", don't double-prefix
        const query = example.i.startsWith('values ')
          ? example.i
          : `values ${example.i}`;
        const [actual, expected] = await Promise.all([
          runSuper(query),
          canonicalExpected(example.o),
        ]);
        // Allow type decorators the example omits (e.g., "29::uint8" vs "29")
        const actualClean = actual.replace(/::\w+$/, '');
        expect([actual, actualClean]).toContain(expected);
      });
    }
  }

  it('covers every recipe that has examples', ({ expect }) => {
    // Guards against the parser silently dropping examples again.
    const withExamples = recipes.filter(r => r.examples.length > 0).length;
    expect(withExamples).toBe(recipes.length - 1); // sk_hex_digits has none
  });
});

// The TypeScript parser feeds skops and the MCP server. Check it against
// super's own evaluation of each skdoc record, so escapes, brackets, and
// quotes inside example text are always read the way super reads them.
describe.concurrent('skdoc parser matches super', () => {
  const rawFile = join(tmpdir(), `superkit-test-raw-${process.pid}.spq`);
  const rawDefs = allSpqFiles
    .map(f => readFileSync(join(recipesDir, f), 'utf-8'))
    .join('\n');
  writeFileSync(rawFile, rawDefs);

  const parsed = new Map(
    allSpqFiles.flatMap(f =>
      parseSkdoc(readFileSync(join(recipesDir, f), 'utf-8'), f.replace(/\.spq$/, ''))
    ).map(r => [r.name, r]),
  );

  const headers = [...rawDefs.matchAll(/^(fn|op)\s+(skdoc_\w+)/gm)];

  it('parses every skdoc declaration', ({ expect }) => {
    expect(parsed.size).toBe(headers.length);
  });

  for (const [, kind, fn] of headers) {
    it(fn, async ({ expect }) => {
      const query = kind === 'fn' ? `values ${fn}()` : `values null | ${fn}`;
      const { stdout: out } = await execFileAsync('super', ['-I', rawFile, '-j', '-c', query], {
        encoding: 'utf-8',
        timeout: 10_000,
      });
      const truth = JSON.parse(out);
      const mine = parsed.get(truth.name);
      expect(mine, `parser missed ${truth.name}`).toBeDefined();
      expect(mine!.description).toBe(truth.desc);
      expect(mine!.examples).toEqual(
        (truth.examples ?? []).map((e: { i: string; o: string }) => ({ i: e.i, o: e.o })),
      );
      expect(mine!.args).toEqual(
        (truth.args ?? []).map((a: Record<string, string | null>) =>
          Object.fromEntries(Object.entries(a).filter(([, v]) => v !== null))),
      );
      expect(mine!.snippet ?? null).toBe(truth.snippet ?? null);
    });
  }
});
