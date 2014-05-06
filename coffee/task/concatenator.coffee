Task = require '../task'


class Concatenator extends Task
  constructor: (@source) ->

  work: (callback) => @clear =>
    @status 0

    try
      concatenated = ''
      for path, source of @source.sources
        if source.tasks.compiler?
          src = source.tasks.compiler.result()
        else
          src = source.tasks.loader.result()

        unless src?
          throw new Error '[Concatenator] Missing source: ' + source.path

        concatenated += src + '\n\n'
      @result concatenated
    catch err
      @error err

    @status 1
    callback?()

module.exports = Concatenator
