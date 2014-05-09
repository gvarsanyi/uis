CoffeeCompiler = require '../task/compiler/coffee'
CoffeeLinter   = require '../task/linter/coffee'
JsFile         = require './js'
Loader         = require '../task/loader'


class CoffeeFile extends JsFile
  constructor: (@repo, @path, @options) ->
    @tasks =
      loader:   new Loader @
      compiler: new CoffeeCompiler @

    unless @options.thirdParty or @options.testOnly
      @tasks.linter = new CoffeeLinter @

module.exports = CoffeeFile
