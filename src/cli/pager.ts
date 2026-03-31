import { spawnSync } from 'child_process';
import { writeFileSync } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';

/**
 * Pipe text through $PAGER (defaults to `less -FRX`).
 * Falls back to stdout if no pager available or not a TTY.
 */
export function pager(text: string): void {
  if (!process.stdout.isTTY) {
    process.stdout.write(text);
    return;
  }

  const pagerCmd = process.env.PAGER || 'less';
  const args = pagerCmd === 'less' ? ['-FRX'] : [];

  // Write to a temp file so the pager can seek
  const tmp = join(tmpdir(), `skdoc-${process.pid}.txt`);
  writeFileSync(tmp, text);

  spawnSync(pagerCmd, [...args, tmp], { stdio: 'inherit' });
}
