const path = require('path')

module.exports = {
  entry: './js/geometrics.ts',
  output: {
    filename: 'geometrics.js',
    path: path.resolve(__dirname, '../priv/static'),
    library: 'geometrics',
    libraryTarget: 'umd',
    globalObject: 'this'
  },
  module: {
    rules: [
      {
        test: path.resolve(__dirname, './js/geometrics.ts'),
      },
      {
        test: /\.(js|ts)$/,
        exclude: /node_modules/,
        use: [
          {
            loader: 'babel-loader',
          },
          {
            loader: 'ts-loader',
          },
        ]
      }
    ]
  },
  plugins: [],
  resolve: {
    extensions: ['.ts', '.js'],
  },
}
