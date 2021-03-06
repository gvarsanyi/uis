CoffeeFile          = require '../file/coffee'
CoffeeFilesCompiler = require '../task/files-compiler/coffee'
CoverageReporter    = require '../task/coverage-reporter'
JsFile              = require '../file/js'
Repo                = require '../repo'
TestFilesDeployer   = require '../task/files-deployer/test'
Tester              = require '../task/tester'
config              = require '../config'
messenger           = require '../messenger'


class TestRepo extends Repo
  extensions: {js: JsFile, coffee: CoffeeFile}

  constructor: ->
    config.test.repos = config.js.repos unless config.test.repos
    super

  getTasks: ->
    filesCompiler:    new CoffeeFilesCompiler @
    filesDeployer:    new TestFilesDeployer @
    tester:           new Tester @
    coverageReporter: new CoverageReporter @

module.exports = new TestRepo

messenger module.exports
