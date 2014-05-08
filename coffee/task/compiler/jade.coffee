jade = require 'jade'

Compiler = require '../compiler'


class JadeCompiler extends Compiler
  work: (callback) => @clear =>
    @status 0

    try
      unless (src = @source.tasks.loader.result())?
        throw new Error '[JadeCompiler] Missing source'

      delete jade.Parser.__includes
      @result jade.render src,
        filename: @source.path
        pretty:   true
      @watch (path for path of jade.Parser?.__includes?[@source.path] or {})
      delete jade.Parser.__includes
    catch err
      @error err

    @status 1
    callback? err

module.exports = JadeCompiler
