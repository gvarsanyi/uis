HtmlDeployer = require '../task/deployer/html'
HtmlFile     = require './html'
HtmlMinifier = require '../task/minifier/html'
JadeCompiler = require '../task/compiler/jade'
Loader       = require '../task/loader'
config       = require '../config'


class JadeFile extends HtmlFile
  constructor: (@repo, @path, @options) ->
    @tasks =
      loader:   new Loader @
      compiler: new JadeCompiler @

    if val = @options.deploy
      @tasks.deployer = new HtmlDeployer @, val

    if val = @options.deployMinified
      @tasks.minifier         = new HtmlMinifier @
      @tasks.minifiedDeployer = new HtmlDeployer @, val, true

module.exports = JadeFile
