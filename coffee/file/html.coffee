File         = require '../file'
HtmlDeployer = require '../task/deployer/html'
HtmlMinifier = require '../task/minifier/html'
Loader       = require '../task/loader'


class HtmlFile extends File
  constructor: (@repo, @path, @options) ->
    @tasks = loader: new Loader @

    if val = @options.deploy
      @tasks.deployer = new HtmlDeployer @, val

    if val = @options.deployMinified
      @tasks.minifier         = new HtmlMinifier @
      @tasks.minifiedDeployer = new HtmlDeployer @, val, true

module.exports = HtmlFile
