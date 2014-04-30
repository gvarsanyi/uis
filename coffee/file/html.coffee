File         = require '../file'
HtmlMinifier = require '../minifier/html'


class HtmlFile extends File
  constructor: ->
    @minifier = new HtmlMinifier @
    super

module.exports = HtmlFile
