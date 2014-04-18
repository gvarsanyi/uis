fs = require 'fs'


class SourceFile
  constructor: (@repo, @path) ->
    fs.readFile @path, encoding: 'utf8', (err, data) =>
      return console.error(err) if err
      @src = data
      @loaded = true
      @repo.update()
      @compiler?.compile(@repo.update) if @compiler


module.exports = SourceFile
