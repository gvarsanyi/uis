CoffeeCompiler = require '../compiler/coffee'
JsFile         = require './js'


class CoffeeFile extends JsFile
  constructor: ->
    @compiler = new CoffeeCompiler @
    super

module.exports = CoffeeFile
