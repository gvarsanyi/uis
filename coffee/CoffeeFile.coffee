CoffeeCompiler = require './CoffeeCompiler'
JsFile         = require './JsFile'


class CoffeeFile extends JsFile
  constructor: ->
    @compiler = new CoffeeCompiler @
    super

module.exports = CoffeeFile
