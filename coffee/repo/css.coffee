CssFile           = require '../file/css'
CssMinifier       = require '../task/minifier/css'
Concatenator      = require '../task/concatenator'
Deployer          = require '../task/deployer'
MinifiedDeployer  = require '../task/minified-deployer'
Repo              = require '../repo'
SassFilesCompiler = require '../task/files-compiler/sass'
SassFile          = require '../file/sass'
config            = require '../config'
messenger         = require '../messenger'


class CssRepo extends Repo
  extensions: {css: CssFile, sass: SassFile, scss: SassFile}

  getTasks: ->
    filesCompiler:    new SassFilesCompiler @
    concatenator:     new Concatenator @
    deployer:         new Deployer @
    minifier:         new CssMinifier @
    minifiedDeployer: new MinifiedDeployer @

module.exports = new CssRepo

messenger module.exports
