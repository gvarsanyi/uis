jade = require 'jade'

Compiler = require '../compiler'


require '../../jade-includes-patch.coffee'


class JadeCompiler extends Compiler
  work: (callback) => @clear =>
    @status 0

    try
      unless (src = @source.tasks.loader.result())?
        throw new Error '[JadeCompiler] Missing source'

      @result jade.render src,
        filename: @source.path
        pretty:   true
        includes: (includes = [])
      @watch includes
    catch err
      console.error err
      process.exit 1
      @error err

    @status 1
    callback? err

module.exports = JadeCompiler
