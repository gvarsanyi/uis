File     = require '../file'
JsLinter = require '../task/linter/js'
Loader   = require '../task/loader'


class JsFile extends File
  constructor: (@repo, @path, @options) ->
    @tasks = loader: new Loader @

    unless @options.thirdParty or @options.testOnly
      @tasks.linter = new JsLinter @

module.exports = JsFile
