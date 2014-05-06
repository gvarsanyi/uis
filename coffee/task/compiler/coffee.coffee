Compiler     = require '../compiler'
Dependencies = require '../dependencies'


class CoffeeCompiler extends Compiler
  compileSrc: (src) ->
    Dependencies::coffee().compile src, bare: true

  compile: (callback) =>
    delete @error
    delete @src

    try
      @src = Dependencies::coffee().compile @source.src, bare: true
    catch err
      @error = err
#       console.error '\nCOFFEE COMPILE ERROR', @source.path, err

    callback? @error, @src

module.exports = CoffeeCompiler
