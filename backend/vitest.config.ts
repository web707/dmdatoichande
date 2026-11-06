import { defineConfig } from 'vitest/config';
export default defineConfig({ test: {
  include: ['test/**/*.test.ts'], fileParallelism: false, testTimeout: 15000,
  coverage: { provider: 'v8', include: ['src/app.ts', 'src/security.ts', 'src/validation.ts', 'src/events.ts'], reporter: ['text', 'lcov'] }
}});
