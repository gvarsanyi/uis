Compiler     = require '../compiler'
Dependencies = require '../dependencies'


class SassCompiler extends Compiler
  compile: (callback) =>
    delete @error
    delete @src

    Dependencies::sass().render
      file: @source.path
      error: (err) =>
        @error = err
#         console.error '\nSASS COMPILE ERROR', @source.path, err
        callback? @error, @src
      success: (data) =>
        @src = data
        callback? @error, @src

module.exports = SassCompiler
