fs = require 'fs'


class SourceFile
  constructor: (@repo, @path) ->
    fs.readFile @path, encoding: 'utf8', (err, data) =>
      return console.error(err) if err
      @src = data
      @loaded = true

      if @constructor.name is 'CoffeeFile'
        @repo.check()
        @compiler.compile()
      else if @compiler
        @compiler.compile =>
          if @minifier
            @minifier.minify @repo.check
          else
            @repo.check()
      else
        @repo.check()

module.exports = SourceFile
