import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Only the TypeScript sources: `npm run build` also emits compiled copies
    // of the tests into dist/, which can be stale.
    include: ['src/**/*.test.ts'],
    testTimeout: 30_000,
  },
});
