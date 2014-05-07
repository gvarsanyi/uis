File         = require '../file'
HtmlDeployer = require '../task/deployer/html'
HtmlMinifier = require '../task/minifier/html'
Loader       = require '../task/loader'
config       = require '../config'


class HtmlFile extends File
  constructor: (@repo, @path, @basedir) ->
    @tasks = loader: new Loader @

    if val = config.deploy?.html
      @tasks.deployer = new HtmlDeployer @, val

    if val = config.minifiedDeploy?.html
      @tasks.minifier         = new HtmlMinifier @
      @tasks.minifiedDeployer = new HtmlDeployer @, val, true

module.exports = HtmlFile
