CssFile      = require '../file/css'
CssMinifier  = require '../task/minifier/css'
Concatenator = require '../task/concatenator'
Deployer     = require '../task/deployer'
Multi        = require '../task/multi'
Repo         = require '../repo'
SassFile     = require '../file/sass'
config       = require '../config'
messenger    = require '../messenger'


class CssRepo extends Repo
  extensions: {css: CssFile, sass: SassFile, scss: SassFile}

  constructor: ->
    @tasks =
      loader:       new Multi @, 'loader'
      compiler:     new Multi @, 'compiler'
      concatenator: new Concatenator @

    if val = config.deploy?.css
      @tasks.deployer = new Deployer @, val

    if val = config.minifiedDeploy?.css
      @tasks.minifier         = new CssMinifier @
      @tasks.minifiedDeployer = new Deployer @, val, true

    super

  fileUpdate: (event, file) =>
    console.log event, file

module.exports = new CssRepo

messenger module.exports
