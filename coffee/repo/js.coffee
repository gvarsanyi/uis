CoffeeFile     = require '../file/coffee'
Deployer       = require '../task/deployer'
JsConcatenator = require '../task/concatenator/js'
JsFile         = require '../file/js'
JsMinifier     = require '../task/minifier/js'
Multi          = require '../task/multi'
Repo           = require '../repo'
config         = require '../config'
messenger      = require '../messenger'


class JsRepo extends Repo
  extensions: {js: JsFile, coffee: CoffeeFile}

  constructor: ->
    @tasks =
      loader:       new Multi @, 'loader'
      concatenator: new JsConcatenator @

    if val = config.deploy?.js
      @tasks.deployer = new Deployer @, val

    if val = config.minifiedDeploy?.js
      @tasks.minifier         = new JsMinifier @
      @tasks.minifiedDeployer = new Deployer @, val, true

    @tasks.compiler = new Multi @, 'compiler'
    @tasks.linter   =  new Multi @, 'linter'
    super

module.exports = new JsRepo

messenger module.exports
