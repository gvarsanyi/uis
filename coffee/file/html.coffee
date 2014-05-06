File         = require '../file'
HtmlDeployer = require '../task/deployer/html'
HtmlMinifier = require '../task/minifier/html'
Loader       = require '../task/loader'


class HtmlFile extends File
  constructor: (@repo, @path, @basedir) ->
    @tasks =
      loader:   new Loader @
      deployer: new HtmlDeployer @
      minifier: new HtmlMinifier @

module.exports = HtmlFile
