Deployable   = require './Deployable'
HtmlFile     = require './HtmlFile'
HtmlMinifier = require './HtmlMinifier'
JadeFile     = require './JadeFile'


class HtmlRepo extends Deployable
  constructor: ->
#     @minifier = new HtmlMinifier @
    super

  extensions: {html: HtmlFile, jade: JadeFile}

module.exports = new HtmlRepo
