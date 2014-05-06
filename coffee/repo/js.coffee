CoffeeFile     = require '../file/coffee'
Deployer       = require '../task/deployer'
JsConcatenator = require '../task/concatenator/js'
JsFile         = require '../file/js'
JsMinifier     = require '../task/minifier/js'
Multi          = require '../task/multi'
Repo           = require '../repo'
messenger      = require '../messenger'


class JsRepo extends Repo
  extensions: {js: JsFile, coffee: CoffeeFile}

  constructor: ->
    @tasks =
      loader:       new Multi @, 'loader'
      concatenator: new JsConcatenator @
      minifier:     new JsMinifier @
      deployer:     new Deployer @
      linter:       new Multi @, 'linter'
      compiler:     new Multi @, 'compiler'
    super

module.exports = new JsRepo

messenger module.exports
