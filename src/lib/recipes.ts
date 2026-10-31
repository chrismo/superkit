import { readFileSync, readdirSync } from 'fs';
import { join, basename } from 'path';
import { getDocsDir } from './docs.js';

export interface RecipeArg {
  name: string;
  desc?: string;
  value?: string;
}

export interface RecipeExample {
  i: string;
  o: string;
}

export interface RecipeFunction {
  name: string;
  type: string;
  description: string;
  args: RecipeArg[];
  examples: RecipeExample[];
  snippet?: string;
  source_file: string;
}

export interface RecipesResult {
  success: boolean;
  recipes: RecipeFunction[];
  count: number;
  error: string | null;
}

type SupValue = string | SupValue[] | { [key: string]: SupValue };

const SUP_ESCAPES: Record<string, string> = {
  '"': '"', "'": "'", '\\': '\\', '/': '/',
  b: '\b', f: '\f', n: '\n', r: '\r', t: '\t',
};

/**
 * Minimal parser for the SUP subset used in skdoc metadata: records with bare
 * or quoted keys, arrays, and single- or double-quoted strings with escapes.
 * Any other scalar (numbers, null, ...) is returned as its raw source text.
 *
 * A real parser (rather than regexes) matters because example text routinely
 * contains brackets, braces, and escaped quotes, e.g. `{a:1} | sk_keys` or
 * `sk_array_append([], \"a\")`.
 */
class SupSubsetParser {
  pos: number;

  constructor(private readonly src: string, start: number) {
    this.pos = start;
  }

  private fail(msg: string): never {
    throw new Error(`${msg} at offset ${this.pos}`);
  }

  private skipSpace(): void {
    while (this.pos < this.src.length) {
      if (/\s/.test(this.src[this.pos])) {
        this.pos++;
      } else if (this.src.startsWith('--', this.pos)) {
        while (this.pos < this.src.length && this.src[this.pos] !== '\n') this.pos++;
      } else {
        break;
      }
    }
  }

  value(): SupValue {
    this.skipSpace();
    const ch = this.src[this.pos];
    if (ch === '{') return this.record();
    if (ch === '[') return this.array();
    if (ch === '"' || ch === "'") return this.string();
    return this.bare();
  }

  private record(): { [key: string]: SupValue } {
    const out: { [key: string]: SupValue } = {};
    this.pos++; // {
    this.skipSpace();
    if (this.src[this.pos] === '}') { this.pos++; return out; }
    for (;;) {
      this.skipSpace();
      const ch = this.src[this.pos];
      let key: string;
      if (ch === '"' || ch === "'") {
        key = this.string();
      } else {
        const m = /^[A-Za-z_$][\w$]*/.exec(this.src.slice(this.pos));
        if (!m) this.fail('expected field name');
        key = m[0];
        this.pos += key.length;
      }
      this.skipSpace();
      if (this.src[this.pos] === '?') this.pos++; // optional field marker
      if (this.src[this.pos] !== ':') this.fail('expected ":"');
      this.pos++;
      out[key] = this.value();
      this.skipSpace();
      const sep = this.src[this.pos++];
      if (sep === '}') return out;
      if (sep !== ',') this.fail('expected "," or "}"');
    }
  }

  private array(): SupValue[] {
    const out: SupValue[] = [];
    this.pos++; // [
    this.skipSpace();
    if (this.src[this.pos] === ']') { this.pos++; return out; }
    for (;;) {
      out.push(this.value());
      this.skipSpace();
      const sep = this.src[this.pos++];
      if (sep === ']') return out;
      if (sep !== ',') this.fail('expected "," or "]"');
    }
  }

  private string(): string {
    const quote = this.src[this.pos++];
    let out = '';
    while (this.pos < this.src.length) {
      const ch = this.src[this.pos++];
      if (ch === quote) return out;
      if (ch !== '\\') { out += ch; continue; }
      const esc = this.src[this.pos++];
      if (esc === 'u') {
        out += String.fromCharCode(parseInt(this.src.slice(this.pos, this.pos + 4), 16));
        this.pos += 4;
      } else if (esc in SUP_ESCAPES) {
        out += SUP_ESCAPES[esc];
      } else {
        out += '\\' + esc;
      }
    }
    this.fail('unterminated string');
  }

  private bare(): string {
    const m = /^[^,\]}\s]+/.exec(this.src.slice(this.pos));
    if (!m) this.fail('unexpected character');
    this.pos += m[0].length;
    return m[0];
  }
}

function asString(v: SupValue | undefined): string | undefined {
  return typeof v === 'string' ? v : undefined;
}

function asRecords(v: SupValue | undefined): { [key: string]: SupValue }[] {
  if (!Array.isArray(v)) return [];
  return v.filter((x): x is { [key: string]: SupValue } =>
    typeof x === 'object' && x !== null && !Array.isArray(x));
}

/**
 * Parse skdoc metadata from .spq source text. Each recipe documents itself
 * with a `fn skdoc_<name>(): (cast({...}, "skdoc"))` (or `op skdoc_<name>:`)
 * declaration whose record holds the metadata.
 */
export function parseSkdoc(content: string, sourceFile: string): RecipeFunction[] {
  const recipes: RecipeFunction[] = [];
  const header = /^(?:fn\s+skdoc_\w+\(\)|op\s+skdoc_\w+)\s*:\s*\(\s*cast\(\s*(?=\{)/gm;
  let match;
  while ((match = header.exec(content)) !== null) {
    try {
      const parsed = new SupSubsetParser(content, header.lastIndex).value();
      if (typeof parsed !== 'object' || Array.isArray(parsed)) continue;
      const recipe = toRecipe(parsed, sourceFile);
      if (recipe) recipes.push(recipe);
    } catch {
      // Skip malformed skdoc entries
    }
  }
  return recipes;
}

function parseSkdocFromFile(filepath: string): RecipeFunction[] {
  return parseSkdoc(readFileSync(filepath, 'utf-8'), basename(filepath, '.spq'));
}

function toRecipe(raw: { [key: string]: SupValue }, sourceFile: string): RecipeFunction | null {
  const name = asString(raw.name);
  const type = asString(raw.type);
  const description = asString(raw.desc);
  if (!name || !type || !description) return null;

  const args: RecipeArg[] = [];
  for (const a of asRecords(raw.args)) {
    const argName = asString(a.name);
    if (!argName) continue;
    const desc = asString(a.desc);
    const value = asString(a.value);
    args.push({
      name: argName,
      ...(desc !== undefined && { desc }),
      ...(value !== undefined && { value }),
    });
  }

  const examples: RecipeExample[] = [];
  for (const e of asRecords(raw.examples)) {
    const i = asString(e.i);
    const o = asString(e.o);
    if (i !== undefined && o !== undefined) examples.push({ i, o });
  }

  const snippet = asString(raw.snippet);

  return {
    name,
    type,
    description,
    args,
    examples,
    ...(snippet !== undefined && { snippet }),
    source_file: sourceFile,
  };
}

/**
 * Load all recipes from the docs/recipes directory.
 */
function loadAllRecipes(): RecipeFunction[] {
  const recipesDir = join(getDocsDir(), 'recipes');
  const files = readdirSync(recipesDir).filter(f => f.endsWith('.spq')).sort();
  const all: RecipeFunction[] = [];
  for (const file of files) {
    const filepath = join(recipesDir, file);
    all.push(...parseSkdocFromFile(filepath));
  }
  return all;
}

/**
 * Search/list available recipe functions.
 */
export function superRecipes(query?: string): RecipesResult {
  try {
    const allRecipes = loadAllRecipes();

    if (!query) {
      return {
        success: true,
        recipes: allRecipes,
        count: allRecipes.length,
        error: null,
      };
    }

    const q = query.toLowerCase();
    const filtered = allRecipes.filter(
      r =>
        r.name.toLowerCase().includes(q) ||
        r.description.toLowerCase().includes(q) ||
        r.source_file.toLowerCase().includes(q)
    );

    return {
      success: true,
      recipes: filtered,
      count: filtered.length,
      error: null,
    };
  } catch (e) {
    return {
      success: false,
      recipes: [],
      count: 0,
      error: e instanceof Error ? e.message : String(e),
    };
  }
}