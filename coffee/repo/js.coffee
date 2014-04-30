CoffeeFile     = require '../file/coffee'
JsConcatenator = require '../concatenator/js'
JsDeployer     = require '../deployer/js'
JsFile         = require '../file/js'
JsMinifier     = require '../minifier/js'
Repo           = require '../repo'
messenger      = require '../messenger'


class JsRepo extends Repo
  constructor: ->
    @concatenator = new JsConcatenator @
    @deployer     = new JsDeployer @
    @minifier     = new JsMinifier @
    super

  extensions: {js: JsFile, coffee: CoffeeFile}

module.exports = new JsRepo

messenger module.exports
