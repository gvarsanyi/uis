CssFile      = require './CssFile'
SassCompiler = require './SassCompiler'


class SassFile extends CssFile
  constructor: ->
    @compiler = new SassCompiler @
    super

module.exports = SassFile
