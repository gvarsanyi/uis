HtmlFile     = require '../file/html'
HtmlMinifier = require '../minifier/html'
JadeFile     = require '../file/jade'
Repo         = require '../repo'
messenger    = require '../messenger'


class HtmlRepo extends Repo
  constructor: ->
    super

  extensions: {html: HtmlFile, jade: JadeFile}

module.exports = new HtmlRepo

messenger module.exports
