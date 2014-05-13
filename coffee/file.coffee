path = require 'path'


class File
  constructor: (@repo, @path, @options) ->

  shortPath: ->
    unless @_shortPath
      @_shortPath = @path
      project_path = path.resolve process.cwd()
      if @_shortPath.substr(0, project_path.length) is project_path
        @_shortPath = @_shortPath.substr project_path.length + 1
    @_shortPath

module.exports = File
