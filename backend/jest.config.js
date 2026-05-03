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

  // Phase 11 / T222 — coverage targets.
  // Conservative baseline (admin, loan_service, jwt, logger 잘 커버됨).
  // 점진 상향: 새 PR마다 코드 추가 시 함께 테스트 추가하여 spec MVP 80%로.
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/server.ts',
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'json-summary'],
  coverageThreshold: {
    global: {
      lines: 35,
      statements: 35,
      functions: 30,
      branches: 25,
    },
  },
};
