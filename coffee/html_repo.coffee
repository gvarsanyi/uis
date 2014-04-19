HtmlFile     = require './HtmlFile'
HtmlMinifier = require './HtmlMinifier'
JadeFile     = require './JadeFile'
Repo         = require './Repo'
messenger    = require './messenger'


class HtmlRepo extends Repo
  constructor: ->
#     @minifier = new HtmlMinifier @
    super

  extensions: {html: HtmlFile, jade: JadeFile}

module.exports = new HtmlRepo

messenger module.exports
