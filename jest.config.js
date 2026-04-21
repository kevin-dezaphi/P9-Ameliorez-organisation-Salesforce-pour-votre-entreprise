const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');

module.exports = {
    ...jestConfig,
    moduleNameMapper: {
        '^@salesforce/apex/(.+)$':
            '<rootDir>/force-app/main/default/lwc/__mocks__/@salesforce/apex/$1.js'
    },
    collectCoverage: true,
    collectCoverageFrom: [
        'force-app/main/default/lwc/**/*.js',
        '!force-app/main/default/lwc/**/__tests__/**',
        '!force-app/main/default/lwc/**/__mocks__/**'
    ],
    coverageReporters: ['text', 'lcov'],
    coverageDirectory: 'coverage'
};