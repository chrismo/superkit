import { readFileSync, readdirSync } from 'fs';
import { join, basename } from 'path';
import { getDocsDir } from './docs.js';
import { getExpertDoc, buildOverview } from './expert-sections.js';

export interface HelpResult {
  success: boolean;
  topic: string;
  content: string;
  sections?: Array<{ slug: string; title: string; lines: number }>;
  web_url?: string;
  error: string | null;
}

/**
 * List available tutorial names from docs/tutorials/
 */
function listTutorials(): string[] {
  const tutorialsDir = join(getDocsDir(), 'tutorials');
  try {
    return readdirSync(tutorialsDir)
      .filter(f => f.endsWith('.md'))
      .map(f => basename(f, '.md'))
      .sort();
  } catch {
    return [];
  }
}

const SITE_BASE = 'https://chrismo.github.io/superkit/_build';

const webUrls: Record<string, string> = {
  'expert': `${SITE_BASE}/expert-guide`,
  'upgrade': `${SITE_BASE}/upgrade-guide`,
  'upgrade-guide': `${SITE_BASE}/upgrade-guide`,
  'migration': `${SITE_BASE}/upgrade-guide`,
  'tutorials': `${SITE_BASE}/tutorials`,
};

/**
 * Get help documentation by topic.
 *
 * Topics: expert, expert:all, expert:<slug>, upgrade, upgrade-guide, migration,
 * tutorials, tutorial:<name>
 */
export function superHelp(topic: string): HelpResult {
  const docsDir = getDocsDir();
  const topics: Record<string, string> = {
    'upgrade': 'zq-to-super-upgrades.md',
    'upgrade-guide': 'zq-to-super-upgrades.md',
    'migration': 'zq-to-super-upgrades.md',
  };

  const normalized = topic.toLowerCase();

  // Handle expert doc topics: expert, expert:all, expert:<slug>
  if (normalized === 'expert' || normalized.startsWith('expert:')) {
    try {
      const doc = getExpertDoc();
      const webUrl = webUrls['expert'];
      const suffix = normalized === 'expert' ? null : normalized.slice('expert:'.length);

      if (suffix === 'all') {
        const filepath = join(docsDir, 'superdb-expert.md');
        const content = readFileSync(filepath, 'utf-8');
        return { success: true, topic, content, web_url: webUrl, error: null };
      }

      if (suffix) {
        const section = doc.sections.find(s => s.slug === suffix);
        if (!section) {
          const available = doc.sections.map(s => `expert:${s.slug}`).join(', ');
          return {
            success: false,
            topic,
            content: '',
            error: `Unknown expert section: ${suffix}. Available sections: ${available}`,
          };
        }
        return { success: true, topic, content: section.content, web_url: webUrl, error: null };
      }

      const content = buildOverview(doc);
      const sections = doc.sections.map(s => ({ slug: s.slug, title: s.title, lines: s.lines }));
      return { success: true, topic, content, sections, web_url: webUrl, error: null };
    } catch (e) {
      return {
        success: false,
        topic,
        content: '',
        error: `Failed to read expert documentation: ${e instanceof Error ? e.message : String(e)}`,
      };
    }
  }

  // Handle "tutorials" topic — list available tutorials
  if (normalized === 'tutorials') {
    const tutorials = listTutorials();
    const listing = tutorials.length > 0
      ? tutorials.map(t => `- tutorial:${t}`).join('\n')
      : 'No tutorials found.';
    return {
      success: true,
      topic,
      content: `# Available Tutorials\n\nUse \`super_help\` with topic \`"tutorial:<name>"\` to read a specific tutorial.\n\n${listing}`,
      web_url: webUrls['tutorials'],
      error: null,
    };
  }

  // Handle "tutorial:<name>" topics
  if (normalized.startsWith('tutorial:')) {
    const tutorialName = normalized.slice('tutorial:'.length);
    const tutorialsDir = join(docsDir, 'tutorials');
    const candidates = [
      `${tutorialName}.md`,
      `${tutorialName.replace(/-/g, '_')}.md`,
      `${tutorialName.replace(/_/g, '-')}.md`,
    ];

    for (const candidate of candidates) {
      try {
        const filepath = join(tutorialsDir, candidate);
        const content = readFileSync(filepath, 'utf-8');
        const resolvedName = basename(candidate, '.md');
        return {
          success: true,
          topic,
          content,
          web_url: `${SITE_BASE}/tutorials/${resolvedName}`,
          error: null,
        };
      } catch {
        // Try next candidate
      }
    }

    const tutorials = listTutorials();
    return {
      success: false,
      topic,
      content: '',
      error: `Unknown tutorial: ${tutorialName}. Available tutorials: ${tutorials.join(', ')}`,
    };
  }

  const filename = topics[normalized];
  if (!filename) {
    const tutorials = listTutorials();
    const allTopics = [
      'expert',
      ...Object.keys(topics),
      'tutorials',
      ...tutorials.map(t => `tutorial:${t}`),
    ];
    return {
      success: false,
      topic,
      content: '',
      error: `Unknown topic: ${topic}. Available topics: ${allTopics.join(', ')}`,
    };
  }

  try {
    const filepath = join(docsDir, filename);
    const content = readFileSync(filepath, 'utf-8');
    return {
      success: true,
      topic,
      content,
      ...(webUrls[normalized] && { web_url: webUrls[normalized] }),
      error: null,
    };
  } catch (e) {
    return {
      success: false,
      topic,
      content: '',
      error: `Failed to read documentation: ${e instanceof Error ? e.message : String(e)}`,
    };
  }
}