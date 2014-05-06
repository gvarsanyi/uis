CssFile      = require '../file/css'
CssMinifier  = require '../task/minifier/css'
Concatenator = require '../task/concatenator'
Deployer     = require '../task/deployer'
Multi        = require '../task/multi'
Repo         = require '../repo'
SassFile     = require '../file/sass'
messenger    = require '../messenger'


class CssRepo extends Repo
  extensions: {css: CssFile, sass: SassFile, scss: SassFile}

  constructor: ->
    @tasks =
      loader:       new Multi @, 'loader'
      compiler:     new Multi @, 'compiler'
      concatenator: new Concatenator @
      minifier:     new CssMinifier @
      deployer:     new Deployer @
    super

module.exports = new CssRepo

messenger module.exports
