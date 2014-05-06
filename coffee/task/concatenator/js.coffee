CoffeeCompiler = require '../compiler/coffee'
Concatenator   = require '../concatenator'


class JsConcatenator extends Concatenator
  concat: (callback) =>
    delete @error
    delete @src

    concatenated = ''

    try
      parts = []
      for path, source of @source.sources
        unless part?.compiled is compiled = source.constructor.name is 'CoffeeFile'
          parts.push part = {compiled, src: ''}
        throw new Error(source.compiler.error) if source.compiler?.error
        part.src += (source.src or '') + '\n\n'

      for part in parts
        if part.compiled
          concatenated += CoffeeCompiler::compileSrc part.src
        else
          concatenated += part.src
      @src = concatenated
    catch err
      @error = err
#       console.error '\nJS CONCAT ERROR', err

    callback? @error, @src

module.exports = JsConcatenator
