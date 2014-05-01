File         = require '../file'
HtmlDeployer = require '../deployer/html'
HtmlMinifier = require '../minifier/html'


class HtmlFile extends File
  constructor: ->
    @deployer = new HtmlDeployer @
    @minifier = new HtmlMinifier @
    super

module.exports = HtmlFile
