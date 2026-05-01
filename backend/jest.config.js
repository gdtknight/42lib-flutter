/**
 * Jest configuration for backend tests.
 *
 * Uses ts-jest preset so .ts test files (and TypeScript modules they import)
 * are type-stripped at test time without a separate build step.
 */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['<rootDir>/tests/**/*.test.ts'],
  moduleFileExtensions: ['ts', 'js', 'json'],
  // Keep tests serial — they share the live Postgres in dev compose and
  // would race on shared rows otherwise.
  maxWorkers: 1,
  testTimeout: 30000,
  // Server only opens an HTTP listener when NODE_ENV !== 'test'.
  globalSetup: '<rootDir>/tests/jest.setup.js',
};
