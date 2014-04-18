HtmlFile     = require './HtmlFile'
JadeCompiler = require './JadeCompiler'


class JadeFile extends HtmlFile
  constructor: ->
    @compiler = new JadeCompiler @
    super

module.exports = JadeFile
