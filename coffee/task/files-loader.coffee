fs = require 'fs'

md5 = require 'MD5'

FilesTask = require '../files-task'


class FilesLoader extends FilesTask
  name:           'filesLoader'
  sourceProperty: 'data'

  followUp: (node) =>
    @source.tasks.filesCompiler.work node

  workFile: => @preWorkFile arguments, (source, callback) =>
    finish = (err, data) =>
      @error(err, source) if err

      source[@sourceProperty] = data

      hash = md5 data or ''
      changed = hash isnt (source.hash or '')
      source.hash = hash

      callback changed

    try
      fs.readFile source.path, encoding: 'utf8', finish
    catch err
      finish err

module.exports = FilesLoader
