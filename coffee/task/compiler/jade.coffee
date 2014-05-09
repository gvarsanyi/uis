jade = require 'jade'

Compiler = require '../compiler'


require '../../jade-includes-patch.coffee'


class JadeCompiler extends Compiler
  work: (callback) => @clear =>
    finish = (err) =>
      @error(err) if err
      @status 1
      callback? err

    @status 0

    try
      unless (src = @source.tasks.loader.result())?
        throw new Error '[JadeCompiler] Missing source'

      @result jade.render src,
        filename: @source.path
        pretty:   true
        includes: (includes = [])

      @watch includes, finish
    catch err
      finish err

module.exports = JadeCompiler