CoffeeCompiler = require '../task/compiler/coffee'
CoffeeLinter   = require '../task/linter/coffee'
JsFile         = require './js'
Loader         = require '../task/loader'


class CoffeeFile extends JsFile
  constructor: (@repo, @path, @basedir) ->
    @tasks =
      loader:   new Loader @
      linter:   new CoffeeLinter @
      compiler: new CoffeeCompiler @

module.exports = CoffeeFile
