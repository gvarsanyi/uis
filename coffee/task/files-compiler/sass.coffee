child_process = require 'child_process'
fs            = require 'fs'
path          = require 'path'

sass = require 'node-sass'

FilesCompiler = require '../files-compiler'


class SassFilesCompiler extends FilesCompiler
  workFile: => @preWorkFile arguments, (source, callback) =>
    stats = {}

    compilers = 0

    finish = (err) =>
      compilers += 1
      @error(err, source) if err
      if compilers is 2 or not source.options.rubysass
        if stats.includedFiles?.length
          # TODO: per-source watchers
          callback()
#           @watch stats.includedFiles, (err) =>
#             @error(err, source) if err
#             callback()
        else
          callback()

    try
      unless source.data?
        throw new Error '[SassFilesCompiler] Missing source: ' + source.path

      if source.options.rubysass
        cmd = 'sass -C -q ' + source.path
        child_process.exec cmd, maxBuffer: 128 * 1024 * 1024, (err, stdout, stderr) =>
          source[@sourceProperty] = stdout unless err
          finish err
    catch err
      @error err, source
      callback()

    try
      node_sass_error = (err) =>
        unless stats.includedFiles?.length
          file = String(err).split(':')[0]
          fs.exists file + '.scss', (exists) =>
            if exists
              stats.includedFiles = [file + '.scss']
              return finish()
            fs.exists file + '.sass', (exists) =>
              if exists
                stats.includedFiles = [file + '.sass']
                return finish()
              fs.exists file, (exists) =>
                if exists
                  stats.includedFiles = [file]
                finish()

      node_sass_success = (data) =>
        source[@sourceProperty] = data unless source.options.rubysass
        finish()

      sass.render
        data:         source.data
        error:        node_sass_error
        includePaths: [path.dirname(source.path) + '/']
        stats:        stats
        success:      node_sass_success
    catch err
      finish err

module.exports = SassFilesCompiler
