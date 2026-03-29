import { readFileSync } from 'fs';
import { join } from 'path';
import { getDocsDir } from './docs.js';

export interface GrokPattern {
  pattern_name: string;
  regex: string;
}

export interface GrokPatternsResult {
  success: boolean;
  patterns: GrokPattern[];
  count: number;
  error: string | null;
}

/**
 * Parse the grok patterns .sup file into structured objects.
 * Each line is a SUP record like: {pattern_name:"FOO",regex:"bar"}
 */
function loadGrokPatterns(): GrokPattern[] {
  const grokPatternsPath = join(getDocsDir(), 'grok-patterns.sup');
  const content = readFileSync(grokPatternsPath, 'utf-8');
  const lines = content.trim().split('\n').filter(Boolean);
  return lines.map(line => {
    const nameMatch = line.match(/pattern_name:"([^"]+)"/);
    const regexMatch = line.match(/regex:"((?:[^"\\]|\\.)*)"/);
    if (!nameMatch || !regexMatch) {
      throw new Error(`Failed to parse grok pattern line: ${line}`);
    }
    return {
      pattern_name: nameMatch[1],
      regex: regexMatch[1],
    };
  });
}

/**
 * Search/filter grok patterns by name or regex content.
 */
export function superGrokPatterns(query?: string): GrokPatternsResult {
  try {
    const allPatterns = loadGrokPatterns();

    if (!query) {
      return {
        success: true,
        patterns: allPatterns,
        count: allPatterns.length,
        error: null,
      };
    }

    const q = query.toLowerCase();
    const filtered = allPatterns.filter(
      p =>
        p.pattern_name.toLowerCase().includes(q) ||
        p.regex.toLowerCase().includes(q)
    );

    return {
      success: true,
      patterns: filtered,
      count: filtered.length,
      error: null,
    };
  } catch (e) {
    return {
      success: false,
      patterns: [],
      count: 0,
      error: e instanceof Error ? e.message : String(e),
    };
  }
}