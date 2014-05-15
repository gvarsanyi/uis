fs   = require 'fs'
path = require 'path'

mkdirp = require 'mkdirp'

FilesTask = require '../files-task'


class FilesDeployer extends FilesTask
  name: 'filesDeployer'

  fileCondition: (source) ->
    not source.options.testOnly

  workFile: => @preWorkFile arguments, (source, callback) =>
    try
      if source.options.minify
        src = source.minified
      else if source.compilable
        src = source.compiled
      else
        src = source.data

      unless src?
        throw new Error '[FilesDeployer] Missing source: ' + source.path
      unless basedir = source.options.basedir
        throw new Error '[FilesDeployer] Missing basedir'
      unless source.path.substr(0, basedir.length) is basedir
        throw new Error '[FilesDeployer]  Path (\'' + source.path +
                        '\' does not begin with basedir: \'' + basedir + '\''

      target = source.options.deploy + source.path.substr basedir.length
      if target.toLowerCase().substr(target.length - 5) is '.jade'
        target = target.substr(0, target.length - 4) + 'html'

      mkdirp path.dirname(target), null, (err) =>
        if err
          @error err, source
          return callback()

        fs.writeFile target, src, (err) =>
          @error(err, source) if err
          callback()
    catch err
      @error err, source
      callback()

module.exports = FilesDeployer
