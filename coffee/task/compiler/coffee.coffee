coffee = require 'coffee-script'

Compiler = require '../compiler'


class CoffeeCompiler extends Compiler
  compileSrc: (src) ->
    coffee.compile src, bare: true

  work: (callback) => @clear =>
    @status 0

    try
      unless (src = @source.tasks.loader.result())?
        throw new Error '[CoffeeCompiler] Missing source'

      @result coffee.compile src, bare: true
    catch err
      @error err

    @status 1
    callback? err

module.exports = CoffeeCompiler
