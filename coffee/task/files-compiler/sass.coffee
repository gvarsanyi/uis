child_process = require 'child_process'
fs            = require 'fs'
path          = require 'path'

try
  sass = require __dirname + '/node_modules/node-sass'
catch
  homedir_key = if process.platform is 'win32' then 'USERPROFILE' else 'HOME'
  sass = require process.env[homedir_key] + '/.uis/node-sass'

FilesCompiler = require '../files-compiler'
config        = require '../../config'
messenger     = require '../../messenger'


class SassFilesCompiler extends FilesCompiler
  workFile: => @preWorkFile arguments, (source, callback) =>
    stats = {}

    compilers = 0

    finish = (err) =>
      compilers += 1
      @error(err, source) if err
      if compilers is 2 or not source.options.rubysass
        unless config.singleRun
          @watch stats.includedFiles, source, (err) =>
            @error(err, source) if err
        callback()

    try
      unless source.data?
        throw new Error '[SassFilesCompiler] Missing source: ' + source.path

      if source.options.rubysass
        bin = 'sass'
        if typeof source.options.rubysass is 'string'
          bin = source.options.rubysass
        cmd = bin + ' --cache-location=' + @source.repoTmp + '../.sass-cache -q ' + source.path
        child_process.exec cmd, maxBuffer: 128 * 1024 * 1024, (err, stdout, stderr) =>
          source[@sourceProperty] = stdout unless err
          finish err
    catch err
      @error err, source
      callback()

    try
      if config.singleRun and source.options.rubysass
        return finish() # no watch required for single run

      node_sass_error = (err) =>
        unless stats.includedFiles?.length
          file = String(err).split(':')[0]
          name = file.split('/').pop()
          dir  = file.substr 0, file.length - name.length
          checks = [file + '.scss',  dir + '_' + name + '.scss', file + '.sass',
                    dir + '_' + name + '.sass', file, dir + '_' + name]
          check_variations = =>
            unless checks.length
              return finish()
            fs.exists (file = checks.shift()), (exists) =>
              if exists
                stats.includedFiles = [file]
                return finish()
              check_variations()
          check_variations()

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

  wrapError: (inf, source) =>
    data = super

    inf = String inf
    lines = (line.trim() for line in inf.split '\n')
    if (parts = lines[0].split ': ')[0] is 'Error' and (desc = parts[3 ...].join ': ').length > 20
      data.title = parts[1] + ': ' + parts[2]
      data.description = desc

      if (parts = lines[1]?.split ' ')[4] and parts[0] is 'on' and parts[1] is 'line' and parts[3] is 'of'
        long_file = parts[4 ...].join ' '
        data.file = @source.shortFile long_file

        data.line = val if (val = Number parts[2]) > 1 or val is 0 or val is 1

        if data.file and data.line
          src = null
          if source.path is long_file
            src = source.data
          else if @_watched[long_file]?.data?
            src = @_watched[long_file].data
          else
            try src = fs.readFileSync long_file, encoding: 'utf8'
          if src? and (lines = String(src).split('\n')).length and lines.length >= data.line
            data.lines =
              from: Math.max 1, data.line - 3
              to:   Math.min lines.length - 1, data.line * 1 + 3
            for line_literal, i in lines[data.lines.from - 1 .. data.lines.to - 1]
              data.lines[i + data.lines.from] = line_literal

    data

module.exports = SassFilesCompiler
