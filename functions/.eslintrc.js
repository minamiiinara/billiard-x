module.exports = {
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "plugin:node/recommended",
  ],
  parserOptions: {
    ecmaVersion: 2018,
  },
  rules: {
    quotes: ["error", "double"],
    "require-jsdoc": "off",
    "max-len": ["error", { code: 90 }],
    "comma-dangle": ["error", "always-multiline"],
    "object-curly-spacing": ["error", "always"],
  },
};
