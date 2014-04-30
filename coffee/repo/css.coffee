CssConcatenator = require '../concatenator/css'
CssDeployer     = require '../deployer/css'
CssFile         = require '../file/css'
CssMinifier     = require '../minifier/css'
Repo            = require '../repo'
SassFile        = require '../file/sass'
messenger       = require '../messenger'


class CssRepo extends Repo
  constructor: ->
    @concatenator = new CssConcatenator @
    @deployer     = new CssDeployer @
    @minifier     = new CssMinifier @
    super

  extensions: {css: CssFile, sass: SassFile, scss: SassFile}

module.exports = new CssRepo

messenger module.exports
