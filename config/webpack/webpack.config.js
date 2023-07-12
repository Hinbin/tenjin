// See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.
const { generateWebpackConfig } = require('shakapacker')
const { merge } = require('webpack-merge')

const webpackConfig = generateWebpackConfig()
const jqueryConfig = require('./jquery.config.js')

module.exports = merge(webpackConfig, jqueryConfig)
