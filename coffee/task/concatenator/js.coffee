CoffeeCompiler = require '../compiler/coffee'
Concatenator   = require '../concatenator'


class JsConcatenator extends Concatenator
  work: (callback) => @clear =>
    @status 0

    try
      parts = []
      for path, source of @source.sources
        unless part?.compiled is compiled = source.constructor.name is 'CoffeeFile'
          parts.push part = {compiled, src: ''}

        unless (src = source.tasks.loader.result())?
          throw new Error '[JsConcatenator] Missing source: ' + source.path

        part.src += src + '\n\n'

      concatenated = ''
      for part in parts
        if part.compiled
          concatenated += CoffeeCompiler::compileSrc part.src
        else
          concatenated += part.src

      @result concatenated
    catch err
      @error err

    @status 1
    callback? err

module.exports = JsConcatenator
