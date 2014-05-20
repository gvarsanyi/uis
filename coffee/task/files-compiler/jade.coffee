jade          = require 'jade'

FilesCompiler = require '../files-compiler'
config        = require '../../config'


require '../../../patch/jade-includes-patch'


class JadeFilesCompiler extends FilesCompiler
  workFile: => @preWorkFile arguments, (source, callback) =>
    try
      unless source.data?
        throw new Error '[JadeFilesCompiler] Missing source: ' + source.path

      source[@sourceProperty] = jade.render source.data,
        filename: source.path
        pretty:   true
        includes: (includes = [])

      unless config.singleRun
        @watch includes, source, (err) =>
          @error(err, source) if err
      callback()
    catch err
      @error err, source
      callback()

module.exports = JadeFilesCompiler
