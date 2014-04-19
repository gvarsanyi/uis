CssConcatenator = require './CssConcatenator'
CssFile         = require './CssFile'
CssMinifier     = require './CssMinifier'
Repo            = require './Repo'
SassFile        = require './SassFile'
messenger       = require './messenger'


class CssRepo extends Repo
  constructor: ->
    @concatenator = new CssConcatenator @
    @minifier     = new CssMinifier @
    super

  extensions: {css: CssFile, sass: SassFile, scss: SassFile}

module.exports = new CssRepo

messenger module.exports
