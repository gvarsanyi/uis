Concatenator        = require '../task/concatenator/js'
CoffeeFile          = require '../file/coffee'
CoffeeFilesCompiler = require '../task/files-compiler/coffee'
CoffeeFilesLinter   = require '../task/files-compiled-linter/coffee'
Deployer            = require '../task/deployer'
JsFile              = require '../file/js'
JsFilesLinter       = require '../task/files-linter/js'
JsMinifier          = require '../task/minifier/js'
MinifiedDeployer    = require '../task/minified-deployer'
Repo                = require '../repo'
Tester              = require '../task/tester'
config              = require '../config'
messenger           = require '../messenger'


class JsRepo extends Repo
  extensions: {js: JsFile, coffee: CoffeeFile}

  getTasks: ->
    filesCompiler:       new CoffeeFilesCompiler @
    concatenator:        new Concatenator @
    deployer:            new Deployer @
    minifier:            new JsMinifier @
    minifiedDeployer:    new MinifiedDeployer @
    filesLinter:         new JsFilesLinter @
    filesCompiledLinter: new CoffeeFilesLinter @
    tester:              new Tester @

module.exports = new JsRepo

messenger module.exports
