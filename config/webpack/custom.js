module.exports = {
  module: {
    rules: [
      { test: /datatables\.net.*/, loader: 'imports-loader?define=>false' }
    ]
  }
}