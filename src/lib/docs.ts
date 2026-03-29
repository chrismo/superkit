import { readdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

/**
 * Resolve the docs/ directory path.
 * Works whether superkit is installed globally (CLI) or in node_modules (MCP dependency).
 */
export function getDocsDir(): string {
  return join(__dirname, '../../docs');
}

/**
 * Get paths to all recipe .spq files.
 * Useful for building -I flags when wrapping the super binary.
 */
export function getRecipeFiles(): string[] {
  const recipesDir = join(getDocsDir(), 'recipes');
  try {
    return readdirSync(recipesDir)
      .filter(f => f.endsWith('.spq'))
      .sort()
      .map(f => join(recipesDir, f));
  } catch {
    return [];
  }
}