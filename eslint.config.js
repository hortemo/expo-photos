const { defineConfig } = require('eslint/config');
const baseConfig = require('expo-module-scripts/eslint.config.base');

const normalizedBaseConfig = Array.isArray(baseConfig) ? baseConfig : [baseConfig];

module.exports = defineConfig([
  {
    ignores: ['build'],
  },
  ...normalizedBaseConfig,
]);
