// config/webpack/webpack.config.js
// Expose jQuery through expose-loader config included
const { generateWebpackConfig, merge } = require('shakapacker')

const customConfig = {
  target: 'web',
  module: {
    rules: [
      {
        test: require.resolve('jquery'),
        loader: 'expose-loader',
        options: {
          exposes: ['$', 'jQuery']
        }
      }
    ]
  }
}

module.exports = merge(generateWebpackConfig(), customConfig)
