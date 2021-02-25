const path = require('path')
const WebpackShellPluginNext = require('webpack-shell-plugin-next');
const outputDirectory = path.resolve(__dirname, '../priv/static');
const typesDirectory = path.resolve(__dirname, './dist')

module.exports = {
  entry: './js/geometrics.ts',
  output: {
    filename: 'geometrics.js',
    path: outputDirectory,
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
  plugins: [
    new WebpackShellPluginNext({
      onBuildExit:{
        scripts: [`cp -R ${typesDirectory}/ ${outputDirectory}`],
        blocking: true,
        parallel: false
      }
    })
  ],
  resolve: {
    extensions: ['.ts', '.js'],
  },
}
