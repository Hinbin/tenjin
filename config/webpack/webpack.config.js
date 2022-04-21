// config/webpack/webpack.config.js
// Expose jQuery through expose-loader config included
const { webpackConfig, merge } = require('shakapacker')
const customConfig = {
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

module.exports = merge(webpackConfig, customConfig)
