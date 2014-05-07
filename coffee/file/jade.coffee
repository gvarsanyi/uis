HtmlDeployer = require '../task/deployer/html'
HtmlFile     = require './html'
HtmlMinifier = require '../task/minifier/html'
JadeCompiler = require '../task/compiler/jade'
Loader       = require '../task/loader'
config       = require '../config'


class JadeFile extends HtmlFile
  constructor: (@repo, @path, @basedir) ->
    @tasks =
      loader:   new Loader @
      compiler: new JadeCompiler @
      minifier: new HtmlMinifier @

    if val = config.deploy?.html
      @tasks.deployer = new HtmlDeployer @, val

    if val = config.minifiedDeploy?.html
      @tasks.minifiedDeployer = new HtmlDeployer @, val, true

module.exports = JadeFile
