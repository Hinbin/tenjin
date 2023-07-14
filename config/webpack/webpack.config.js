// See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.
const { generateWebpackConfig, inliningCss } = require('shakapacker')
const { merge } = require('webpack-merge')
const ReactRefreshWebpackPlugin = require('@pmmmwh/react-refresh-webpack-plugin')
const isDevelopment = process.env.NODE_ENV !== 'production'
const webpackConfig = generateWebpackConfig()
const jqueryConfig = require('./jquery.config.js')
const hotLoadingConfig = require('./hotloading.config.js')
const ignoreWarningsConfig = require('./ignoreWarnings.config.js')

if (isDevelopment && inliningCss) {
  webpackConfig.plugins.push(
    new ReactRefreshWebpackPlugin({
      overlay: {
        sockPort: webpackConfig.devServer.port,
      },
    })
  )
}

module.exports = merge(
  webpackConfig,
  jqueryConfig,
  hotLoadingConfig,
  ignoreWarningsConfig
)
