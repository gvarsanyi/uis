fs = require 'fs'

md5 = require 'MD5'

FilesTask = require '../files-task'


class FilesLoader extends FilesTask
  name:           'filesLoader'
  sourceProperty: 'data'

  followUp: =>
    @source.tasks.filesCompiler.work()
    @source.tasks.concatenator.work() if @source.name is 'js'
    @source.tasks.filesLinter?.work()
    @source.tasks.filesCompiledLinter?.work()

  workFile: => @preWorkFile arguments, (source, callback) =>
    finish = (err, data) =>
      @error(err) if err

      source[@sourceProperty] = data

      hash = md5 data or ''
      if hash isnt source.hash or ''
        changed = true
      source.hash = hash

      callback changed

    try
      fs.readFile source.path, encoding: 'utf8', finish
    catch err
      finish err

module.exports = FilesLoader
