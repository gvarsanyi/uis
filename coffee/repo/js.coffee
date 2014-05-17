CoffeeFile          = require '../file/coffee'
CoffeeFilesCompiler = require '../task/files-compiler/coffee'
Deployer            = require '../task/deployer'
JsConcatenator      = require '../task/concatenator/js'
JsFile              = require '../file/js'
JsFilesLinter       = require '../task/files-linter/js'
JsMinifier          = require '../task/minifier/js'
Repo                = require '../repo'
config              = require '../config'
messenger           = require '../messenger'


class JsRepo extends Repo
  extensions: {js: JsFile, coffee: CoffeeFile}

  getTasks: ->
    filesCompiler: new CoffeeFilesCompiler @
    concatenator:  new JsConcatenator @
    minifier:      new JsMinifier @
    deployer:      new Deployer @
    filesLinter:   new JsFilesLinter @

module.exports = new JsRepo

messenger module.exports
