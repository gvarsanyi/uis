jade = require 'jade'

FilesCompiler = require '../files-compiler'


require '../../jade-includes-patch'


class JadeFilesCompiler extends FilesCompiler
  workFile: => @preWorkFile arguments, (source, callback) =>
    try
      unless source.data?
        throw new Error '[JadeFilesCompiler] Missing source: ' + source.path

      source[@sourceProperty] = jade.render source.data,
        filename: source.path
        pretty:   true
        includes: (includes = [])

      if includes.length
        # TODO: per-source watchers
        callback()
#         @watch includes, (err) =>
#           @error(err) if err
#           callback()
      else
        callback()
    catch err
      @error err
      callback()

module.exports = JadeFilesCompiler
