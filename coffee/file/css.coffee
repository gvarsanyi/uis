File   = require '../file'
Loader = require '../task/loader'


class CssFile extends File
  constructor: (@repo, @path, @options) ->
    @tasks =
      loader: new Loader @

module.exports = CssFile
