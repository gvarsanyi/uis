jslint = require 'jslint'

Linter = require '../linter'


class JsLinter extends Linter
  work: (callback) => @clear =>
    @status 0

    try
      unless (src = @source.tasks.loader.result())?
        throw new Error '[JsLinter] Missing source'

      worker = jslint.load 'latest'
      worker src

      for msg in worker.errors
        @warning msg
    catch err
      @error err

    @status 1
    callback? err

module.exports = JsLinter
