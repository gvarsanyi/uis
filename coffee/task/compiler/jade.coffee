Compiler     = require '../compiler'
Dependencies = require '../dependencies'


class JadeCompiler extends Compiler
  compile: (callback) =>
    delete @error
    delete @src

    try
      @src = Dependencies::jade().render @source.src,
        filename: @source.path
        pretty:   true
    catch err
      @error = err
#       console.error '\nJADE COMPILE ERROR', @source.path, err

    callback? @error, @src

module.exports = JadeCompiler
