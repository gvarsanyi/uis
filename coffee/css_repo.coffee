CssConcatenator = require './CssConcatenator'
CssFile         = require './CssFile'
CssMinifier     = require './CssMinifier'
Deployable      = require './Deployable'
SassFile        = require './SassFile'


class CssRepo extends Deployable
  constructor: ->
    @concatenator = new CssConcatenator @
    @minifier     = new CssMinifier @
    super

  extensions: {css: CssFile, sass: SassFile, scss: SassFile}

module.exports = new CssRepo
