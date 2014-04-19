fs = require 'fs'


class SourceFile
  constructor: (@repo, @path) ->
    fs.readFile @path, encoding: 'utf8', (err, data) =>
      return console.error(err) if err
      @src = data
      @loaded = true

      if @compiler
        @compiler.compile @repo.check
      else
        @repo.check()

module.exports = SourceFile
