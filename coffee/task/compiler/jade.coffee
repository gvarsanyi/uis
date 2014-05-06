jade = require 'jade'

Compiler = require '../compiler'


class JadeCompiler extends Compiler
  work: (callback) => @clear =>
    @status 0

    try
      unless (src = @source.tasks.loader.result())?
        throw new Error '[JadeCompiler] Missing source'

      @result jade.render src,
        filename: @source.path
        pretty:   true
    catch err
      @error err

    @status 1
    callback?()

module.exports = JadeCompiler
