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

/**
 * Parse skdoc metadata from a .spq file.
 */
function parseSkdocFromFile(filepath: string): RecipeFunction[] {
  const content = readFileSync(filepath, 'utf-8');
  const sourceFile = basename(filepath, '.spq');
  const recipes: RecipeFunction[] = [];

  const skdocPattern = /fn\s+skdoc_\w+\(\):\s*\(\s*cast\(\s*(\{[\s\S]*?\}),\s*<skdoc>\)/g;
  const skdocOpPattern = /op\s+skdoc_\w+:\s*\(\s*cast\(\s*(\{[\s\S]*?\}),\s*<skdoc>\)/g;

  for (const pattern of [skdocPattern, skdocOpPattern]) {
    let match;
    while ((match = pattern.exec(content)) !== null) {
      try {
        const raw = match[1];
        const recipe = parseSkdocObject(raw, sourceFile);
        if (recipe) {
          recipes.push(recipe);
        }
      } catch {
        // Skip malformed skdoc entries
      }
    }
  }

  return recipes;
}

/**
 * Parse a SUP-format skdoc object into a RecipeFunction.
 */
function parseSkdocObject(raw: string, sourceFile: string): RecipeFunction | null {
  const nameMatch = raw.match(/name:"([^"]+)"/);
  const typeMatch = raw.match(/type:"([^"]+)"/);
  const descMatch = raw.match(/desc:"([^"]+)"/);

  if (!nameMatch || !typeMatch || !descMatch) {
    return null;
  }

  const args: RecipeArg[] = [];
  const argsMatch = raw.match(/args:\[([\s\S]*?)\]/);
  if (argsMatch) {
    const argsContent = argsMatch[1];
    const argPattern = /\{([^}]+)\}/g;
    let argMatch;
    while ((argMatch = argPattern.exec(argsContent)) !== null) {
      const argObj = argMatch[1];
      const argName = argObj.match(/name:"([^"]+)"/);
      const argDesc = argObj.match(/desc:"([^"]+)"/);
      const argValue = argObj.match(/value:"([^"]+)"/);
      if (argName) {
        args.push({
          name: argName[1],
          ...(argDesc && { desc: argDesc[1] }),
          ...(argValue && { value: argValue[1] }),
        });
      }
    }
  }

  const examples: RecipeExample[] = [];
  const examplesMatch = raw.match(/examples:\[([\s\S]*?)\]/);
  if (examplesMatch) {
    const exContent = examplesMatch[1];
    const exPattern = /\{([^}]+)\}/g;
    let exMatch;
    while ((exMatch = exPattern.exec(exContent)) !== null) {
      const exObj = exMatch[1];
      const iMatch = exObj.match(/i:"([^"]+)"/);
      const oMatch = exObj.match(/o:"([^"]+)"/);
      if (iMatch && oMatch) {
        examples.push({ i: iMatch[1], o: oMatch[1] });
      }
    }
  }

  const snippetMatch = raw.match(/snippet:'([^']+)'/);

  return {
    name: nameMatch[1],
    type: typeMatch[1],
    description: descMatch[1],
    args,
    examples,
    ...(snippetMatch && { snippet: snippetMatch[1] }),
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