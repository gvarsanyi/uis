CoffeeFile     = require './CoffeeFile'
JsConcatenator = require './JsConcatenator'
JsFile         = require './JsFile'
JsMinifier     = require './JsMinifier'
Repo           = require './Repo'
messenger      = require './messenger'


class JsRepo extends Repo
  constructor: ->
    @concatenator = new JsConcatenator @
    @minifier     = new JsMinifier @
    super

  extensions: {js: JsFile, coffee: CoffeeFile}

module.exports = new JsRepo

messenger module.exports
