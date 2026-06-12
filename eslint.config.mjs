import eslintPluginPrettierRecommended from "eslint-plugin-prettier/recommended";

export default [
  {
    languageOptions: {
      ecmaVersion: 2022,
    },
    rules: {
      "prefer-const": "error",
    },
    files: ["**/*.js", "**/*.mjs"],
  },
  eslintPluginPrettierRecommended,
];
