coffee = require 'coffee-script'

Concatenator = require '../concatenator'


class JsConcatenator extends Concatenator
  work: => @preWork arguments, (callback) =>
    try
      parts = []
      for path, source of @source.sources
        unless part?.compiled is compiled = source.constructor.name is 'CoffeeFile'
          parts.push part = {compiled, src: ''}

        unless source.data?
          throw new Error '[JsConcatenator] Missing source: ' + source.path

        part.src += source.data + '\n\n'

      concatenated = ''
      for part in parts
        if part.compiled
          concatenated += coffee.compile part.src, bare: true
        else
          concatenated += part.src

      callback null, concatenated
    catch err
      callback err

module.exports = JsConcatenator
