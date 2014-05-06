HtmlDeployer = require '../task/deployer/html'
HtmlFile     = require './html'
HtmlMinifier = require '../task/minifier/html'
JadeCompiler = require '../task/compiler/jade'
Loader       = require '../task/loader'


class JadeFile extends HtmlFile
  constructor: (@repo, @path, @basedir) ->
    @tasks =
      loader:   new Loader @
      compiler: new JadeCompiler @
      deployer: new HtmlDeployer @
      minifier: new HtmlMinifier @

module.exports = JadeFile
