HtmlFile     = require './html'
JadeCompiler = require '../compiler/jade'


class JadeFile extends HtmlFile
  constructor: ->
    @compiler = new JadeCompiler @
    super

module.exports = JadeFile
