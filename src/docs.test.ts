import { describe, it, expect } from 'vitest';
import { readFileSync, readdirSync } from 'fs';
import { join } from 'path';

const repoRoot = join(import.meta.dirname, '..');
const docsDir = join(repoRoot, 'docs');
const pinned = readFileSync(join(repoRoot, '.superdb-version'), 'utf-8').trim().replace(/^v/, '');

function markdownFiles(dir: string): string[] {
  return readdirSync(dir, { withFileTypes: true }).flatMap(e => {
    const p = join(dir, e.name);
    if (e.isDirectory()) return markdownFiles(p);
    return e.name.endsWith('.md') ? [p] : [];
  });
}

// CI runs the docs against the release in .superdb-version, so every doc that
// declares a superdb_version must claim that same release.
describe('docs target the pinned SuperDB release', () => {
  const docs = markdownFiles(docsDir)
    .map(path => ({ path, m: readFileSync(path, 'utf-8').match(/^superdb_version:\s*"([^"]+)"/m) }))
    .filter(d => d.m);

  it('has docs that declare a version', () => {
    expect(docs.length).toBeGreaterThan(0);
  });

  for (const { path, m } of docs) {
    it(path.slice(repoRoot.length + 1), () => {
      expect(m![1]).toBe(pinned);
    });
  }
});
