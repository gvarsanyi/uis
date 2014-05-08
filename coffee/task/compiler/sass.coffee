path = require 'path'

sass = require 'node-sass'

Compiler = require '../compiler'


class SassCompiler extends Compiler
  work: (callback) => @clear =>
    @status 0

    stats = {}

    finish = (err) =>
      @error(err) if err
      @watch stats.includedFiles, (err2) =>
        @status 1
        callback? err or err2

    try
      sass.render
        data:         @source.tasks.loader.result()
        error:        finish
        includePaths: [path.dirname(@source.path) + '/']
        stats:        stats
        success:      (data) =>
          @result data
          finish()
    catch err
      finish err

module.exports = SassCompiler
