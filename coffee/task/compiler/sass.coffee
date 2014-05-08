sass = require 'node-sass'

Compiler = require '../compiler'


class SassCompiler extends Compiler
  work: (callback) => @clear =>
    @status 0

    sass.render
      file: @source.path
      success: (data) =>
        @result data
        @status 1
        callback?()
      error: (err) =>
        @error err
        @status 1
        callback? err

module.exports = SassCompiler
