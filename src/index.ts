// Content resolution
export { getDocsDir, getRecipeFiles } from './lib/docs.js';

// Help / documentation
export { superHelp } from './lib/help.js';
export type { HelpResult } from './lib/help.js';

// Expert guide sections
export { getExpertDoc, buildOverview, parseExpertDoc, clearExpertCache, SECTION_SLUGS } from './lib/expert-sections.js';
export type { ExpertSection, ParsedExpertDoc } from './lib/expert-sections.js';

// Grok patterns
export { superGrokPatterns } from './lib/grok.js';
export type { GrokPattern, GrokPatternsResult } from './lib/grok.js';

// Recipes
export { superRecipes } from './lib/recipes.js';
export type { RecipeFunction, RecipeArg, RecipeExample, RecipesResult } from './lib/recipes.js';