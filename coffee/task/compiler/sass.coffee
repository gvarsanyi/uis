child_process = require 'child_process'
fs            = require 'fs'
path          = require 'path'

sass = require 'node-sass'

Compiler = require '../compiler'


class SassCompiler extends Compiler
  work: (callback) => @clear =>
    @status 0

    stats = {}

    compilers = 0

    finish = (err) =>
      compilers += 1
      @error(err) if err
      if compilers is 2 or not @source.options.rubysass
        if stats.includedFiles?.length
          @watch stats.includedFiles, (err) =>
            @error(err) if err
            @status 1
            callback? @error()
        else
          callback? @error()

    try
      if @source.options.rubysass
        cmd = 'sass -C -q ' + @source.path
        child_process.exec cmd, maxBuffer: 128 * 1024 * 1024, (err, stdout, stderr) =>
          @result(stdout) unless err
          finish err

      sass.render
        data:         @source.tasks.loader.result()
        error:        (err) =>
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
        includePaths: [path.dirname(@source.path) + '/']
        stats:        stats
        success:      (data) =>
          unless @source.options.rubysass
            @result data
          finish()
    catch err
      finish err

module.exports = SassCompiler
