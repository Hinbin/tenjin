// config/webpack/environment.js
const { environment } = require('@rails/webpacker')
const customConfig = require('./custom')

// Merge custom config
environment.config.merge(customConfig)
environment.config.merge({ devtool: 'none' })

module.exports = environment
