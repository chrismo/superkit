#!/usr/bin/env node

import { superHelp } from '../lib/help.js';
import { pager } from './pager.js';

const topic = process.argv[2];

if (!topic) {
  const result = superHelp('expert');
  if (!result.success) {
    console.error(result.error);
    process.exit(1);
  }

  const lines = [
    'SuperKit Documentation Browser',
    '',
    'Usage: skdoc <topic>',
    '',
    'Topics:',
    '  expert              Expert guide overview (sections listed below)',
    '  expert:all          Full expert guide',
    '  expert:<section>    Specific expert section',
    '  upgrade             SuperDB upgrade/migration guide',
    '  tutorials           List available tutorials',
    '  tutorial:<name>     Specific tutorial',
    '',
  ];

  if (result.sections) {
    lines.push('Expert guide sections:');
    for (const s of result.sections) {
      lines.push(`  expert:${s.slug.padEnd(24)} ${s.title}`);
    }
    lines.push('');
  }

  pager(lines.join('\n'));
} else {
  const result = superHelp(topic);
  if (!result.success) {
    console.error(result.error);
    process.exit(1);
  }
  pager(result.content);
}
