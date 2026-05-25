// See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.
const { generateWebpackConfig, merge, web } = require("shakapacker");
const webpack = require("webpack");
const webpackConfig = generateWebpackConfig();

const options = {
  resolve: {
    extensions: [".css", ".scss", ".ts"],
  },
  module: {
    rules: [
      {
        test: /\.scss$/,
        use: ["style-loader", "css-loader", "sass-loader"],
      },
      {
        test: /\.css$/,
        use: ["style-loader", "css-loader"],
      },
    ],
  },
  plugins: [
    new webpack.ProvidePlugin({
      $: "jquery",
      jQuery: "jquery",
      Popper: ["popper.js", "default"],
      Rails: ["@rails/ujs"],
    }),
  ],
};

module.exports = merge(options, webpackConfig);
