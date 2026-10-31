#!/usr/bin/env node
// Run the mdtest examples embedded in the docs against the `super` on PATH.
//
// This follows the conventions of the mdtest package in superdb/super
// (https://github.com/superdb/super/blob/main/mdtest/mdtest.go):
//
//   ```mdtest-input file.sup     writes file.sup into the doc's temp dir
//   ```mdtest-command [fails]    runs with `bash -e -o pipefail`
//   ```mdtest-output [head]      must match combined stdout+stderr exactly
//                                ("head": a trailing "..." line allows more)
//
// Each Markdown file gets its own temporary working directory, shared by all
// of its commands, so later commands can read files that earlier ones wrote.
// The `dir=` option of mdtest-command isn't supported (no docs here use it).
//
// Usage:
//   node scripts/mdtest.mjs [--skip <substring>]... [path ...]
//
// Paths default to the docs/ directory. A path can be a file or a directory
// (searched recursively for .md files). `--skip` skips commands whose text
// contains the substring, e.g. `--skip lichess.org` when offline.

import { spawnSync } from 'node:child_process';
import { mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, relative } from 'node:path';

const FENCE = /^```(mdtest-[a-z]+)(?:[ \t]+(.*))?$/;

function parseArgs(argv) {
  const paths = [];
  const skips = [];
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--skip') skips.push(argv[++i]);
    else if (argv[i] === '-h' || argv[i] === '--help') {
      console.log('usage: mdtest.mjs [--skip <substring>]... [path ...]');
      process.exit(0);
    } else paths.push(argv[i]);
  }
  return { paths: paths.length ? paths : ['docs'], skips };
}

function markdownFiles(path) {
  if (statSync(path).isFile()) return [path];
  return readdirSync(path, { withFileTypes: true })
    .sort((a, b) => a.name.localeCompare(b.name))
    .flatMap(e => {
      const p = join(path, e.name);
      if (e.isDirectory()) return markdownFiles(p);
      return e.name.endsWith('.md') ? [p] : [];
    });
}

function* blocks(text) {
  const lines = text.split('\n');
  for (let i = 0; i < lines.length; i++) {
    const m = FENCE.exec(lines[i]);
    if (!m) continue;
    const start = i + 1;
    let end = start;
    while (end < lines.length && !lines[end].startsWith('```')) end++;
    if (end >= lines.length) throw new Error(`unterminated ${m[1]} block at line ${i + 1}`);
    yield { kind: m[1], words: (m[2] ?? '').trim().split(/\s+/).filter(Boolean), body: lines.slice(start, end).join('\n'), line: i + 1 };
    i = end;
  }
}

function matches(got, want, head) {
  if (head && (want === '...' || want.endsWith('\n...'))) {
    return got.startsWith(want.slice(0, -3));
  }
  return got === want;
}

function diff(want, got) {
  const w = want.split('\n');
  const g = got.split('\n');
  const out = [];
  for (let i = 0; i < Math.max(w.length, g.length); i++) {
    if (w[i] === g[i]) continue;
    if (w[i] !== undefined) out.push(`    - ${w[i]}`);
    if (g[i] !== undefined) out.push(`    + ${g[i]}`);
  }
  return out.join('\n');
}

const { paths, skips } = parseArgs(process.argv.slice(2));
let passed = 0;
let skipped = 0;
const failures = [];

for (const file of paths.flatMap(markdownFiles)) {
  const name = relative(process.cwd(), file);
  const dir = mkdtempSync(join(tmpdir(), 'mdtest-'));
  let pending = null;
  try {
    for (const b of blocks(readFileSync(file, 'utf-8'))) {
      if (b.kind === 'mdtest-input') {
        writeFileSync(join(dir, b.words[0]), b.body + '\n');
      } else if (b.kind === 'mdtest-command') {
        if (pending) throw new Error(`${name}:${pending.line}: mdtest-command without mdtest-output`);
        pending = b;
      } else if (b.kind === 'mdtest-output') {
        if (!pending) throw new Error(`${name}:${b.line}: mdtest-output without mdtest-command`);
        const cmd = pending;
        pending = null;
        if (skips.some(s => cmd.body.includes(s))) {
          skipped++;
          continue;
        }
        // `exec 2>&1` merges stderr into the stdout pipe so output keeps the
        // order in which it was written, as with Go's CombinedOutput.
        const r = spawnSync('bash', ['-e', '-o', 'pipefail'], {
          cwd: dir,
          input: `exec 2>&1\n${cmd.body}\n`,
          encoding: 'utf-8',
          timeout: 120_000,
        });
        const got = (r.stdout ?? '').replace(/\n+$/, '');
        const want = b.body.replace(/\n+$/, '');
        const expectFail = cmd.words.includes('fails');
        const failedAsExpected = (r.status !== 0) === expectFail;
        if (failedAsExpected && matches(got, want, b.words.includes('head'))) {
          passed++;
        } else {
          let msg = `FAIL ${name}:${cmd.line} (exit ${r.status ?? r.signal}${expectFail ? ', expected failure' : ''})`;
          msg += '\n' + cmd.body.split('\n').map(l => `    $ ${l}`).join('\n');
          msg += '\n' + diff(want, got);
          failures.push(msg);
        }
      }
    }
    if (pending) throw new Error(`${name}:${pending.line}: mdtest-command without mdtest-output`);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

for (const f of failures) console.log(f + '\n');
const summary = `mdtest: ${passed} passed, ${failures.length} failed` + (skipped ? `, ${skipped} skipped` : '');
console.log(summary);
process.exit(failures.length ? 1 : 0);
