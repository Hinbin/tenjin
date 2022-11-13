// config/webpack/webpack.config.js
// Expose jQuery through expose-loader config included
const { webpackConfig, merge, inliningCss } = require('shakapacker')

const ReactRefreshWebpackPlugin = require('@pmmmwh/react-refresh-webpack-plugin')
const isDevelopment = process.env.NODE_ENV !== 'production'

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

if (isDevelopment && inliningCss) {
  webpackConfig.plugins.push(
    new ReactRefreshWebpackPlugin({
      overlay: {
        sockPort: webpackConfig.devServer.port
      }
    })
  )
}

module.exports = merge(webpackConfig, customConfig)
