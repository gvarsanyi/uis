CssFile      = require './css'
Loader       = require '../task/loader'
SassCompiler = require '../task/compiler/sass'


class SassFile extends CssFile
  constructor: (@repo, @path, @basedir) ->
    @tasks =
      loader:   new Loader @
      compiler: new SassCompiler @

module.exports = SassFile
