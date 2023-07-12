// Expose jQuery through expose-loader config included
module.exports = {
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
