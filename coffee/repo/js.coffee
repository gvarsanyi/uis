CoffeeFile     = require '../file/coffee'
Deployer       = require '../task/deployer'
JsConcatenator = require '../task/concatenator/js'
JsFile         = require '../file/js'
JsMinifier     = require '../task/minifier/js'
Multi          = require '../task/multi'
Repo           = require '../repo'
Tester         = require '../task/tester'
config         = require '../config'
messenger      = require '../messenger'


class JsRepo extends Repo
  extensions: {js: JsFile, coffee: CoffeeFile}

  getTasks: ->
    tasks =
      compiler:     new Multi @, 'compiler'
      concatenator: new JsConcatenator @

    if val = config[@name].deploy
      tasks.deployer = new Deployer @, val

    if val = config[@name].deployMinified
      tasks.minifier         = new JsMinifier @
      tasks.minifiedDeployer = new Deployer @, val, true

    tasks.linter = new Multi @, 'linter'

    if config[@name].test?.files
      tasks.tester = new Tester @

    tasks

module.exports = new JsRepo

messenger module.exports
