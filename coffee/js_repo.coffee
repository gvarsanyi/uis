CoffeeFile     = require './CoffeeFile'
Deployable     = require './Deployable'
JsConcatenator = require './JsConcatenator'
JsFile         = require './JsFile'
JsMinifier     = require './JsMinifier'


class JsRepo extends Deployable
  constructor: ->
    @concatenator = new JsConcatenator @
    @minifier     = new JsMinifier @
    super

  extensions: {js: JsFile, coffee: CoffeeFile}

module.exports = new JsRepo
