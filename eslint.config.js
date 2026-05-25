const eslintPluginPrettierRecommended = require("eslint-plugin-prettier/recommended");
const babelParser = require("@babel/eslint-parser");

module.exports = [
  {
    languageOptions: {
      ecmaVersion: 2020,
    },
    rules: {
      "prefer-const": "error",
    },
    files: ["**/*.js", "**/*.mjs"],
    languageOptions: {
      parser: babelParser,
    },
  },
  eslintPluginPrettierRecommended,
];
