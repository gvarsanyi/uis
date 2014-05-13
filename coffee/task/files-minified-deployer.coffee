fs   = require 'fs'
path = require 'path'

mkdirp = require 'mkdirp'

FilesTask = require '../files-task'


class FilesMinifiedDeployer extends FilesTask
  name: 'filesMinifiedDeployer'

  fileCondition: (source) ->
    source.options.deployMinified and not source.options.testOnly

  workFile: => @preWorkFile arguments, (source, callback) =>
    try
      unless source.minified?
        throw new Error '[FilesMinifiedDeployer] Missing source: ' + source.path
      unless basedir = source.options.basedir
        throw new Error '[FilesMinifiedDeployer] Missing basedir'
      unless source.path.substr(0, basedir.length) is basedir
        throw new Error '[FilesMinifiedDeployer]  Path (\'' + source.path +
                        '\' does not begin with basedir: \'' + basedir + '\''

      target = source.options.deployMinified + source.path.substr basedir.length
      if target.toLowerCase().substr(target.length - 5) is '.jade'
        target = target.substr(0, target.length - 4) + 'html'

      mkdirp path.dirname(target), null, (err) =>
        if err
          @error err
          callback()

        fs.writeFile target, source.minified, (err) =>
          @error(err) if err
          callback()
    catch err
      @error err

    callback()

module.exports = FilesMinifiedDeployer
