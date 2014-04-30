CssFile      = require './css'
SassCompiler = require '../compiler/sass'


class SassFile extends CssFile
  constructor: ->
    @compiler = new SassCompiler @
    super

module.exports = SassFile
