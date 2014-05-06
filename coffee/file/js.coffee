File     = require '../file'
# JsLinter = require '../task/linter/js'
Loader   = require '../task/loader'


class JsFile extends File
  constructor: (@repo, @path, @basedir) ->
    @tasks =
      loader: new Loader @
#       linter: new JsLinter @

module.exports = JsFile
