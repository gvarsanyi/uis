fs        = require 'fs'

karma     = require 'karma'

Task      = require '../task'
config    = require '../config'
messenger = require '../messenger'


class Tester extends Task
  name: 'tester'

  listeners: @

  condition: =>
    !!config[@source.name].files and @source.tasks.filesLoader?.count()

  size: =>
    @_result or 0

  work: => @preWork (args = arguments), (callback) =>
    if typeof args[0] is 'object' and args[0].file and @_watched[args[0].file]
      updated_file = args[0].file

    finished = false
    finish = =>
      return if finished
      finished = true

      process.stdout.write = orig_stdout if orig_stdout
      process.stderr.write = orig_stderr if orig_stderr

      for line, i in stdout or []
        if (index = line.indexOf 'PhantomJS 1.9.7 (Linux): Executed ') > -1
          if result = Number line.substr(index + 25).split(' ')[3]
            @result result
        else if line.substr(0, 6) is '    ✗ '
          @warning(warning) if warning
          warning =
            file:  stdout[i - 1].trim()
            title: line.substr 6
        else if line.substr(0, 1) is '\t' and line.trim() and warning
          if warning.description
            warning.description += '\n' + line.trim()
          else
            warning.description = line.trim()
        else unless line
          if warning
            @warning warning
            warning = null
        else if line.substr(0, 29) is 'ERROR [preprocessor.coffee]: '
          inf =
            description: line.substr(29)
            title: 'Compilation Error'
          if stdout[i + 1].substr(0, 5) is '  at '
            parts = stdout[i + 1].substr(5).split ':'
            line = null
            unless isNaN val = Number parts[parts.length - 1]
              inf.line = val
              parts.pop()
            inf.file = parts.join ':'
          @error inf
#         else if line
#           console.log line

      @warning(warning) if warning
      callback()

    try
      deployment = []
      for item in config.test.repos
        list = item.repo
        list = [list] unless typeof list is 'object'
        for repo in list
          deployment.push @source.repoTmp + 'clone/' + repo

      unless config.test.files and typeof config.test.files is 'object'
        config.test.files = [config.test.files]
      testables = if updated_file then [updated_file] else config.test.files

      options =
        autoWatch:     false
        browsers:      ['PhantomJS']
        colors:        false
        files:         deployment.concat testables
        frameworks:    ['jasmine']
        logLevel:      'WARN'
        preprocessors: {}
        reporters:     ['spec']
        singleRun:     true
        specReporter:  suppressPassed: true

      for test_file in testables when test_file.indexOf('.coffee') > -1
        options.preprocessors[test_file] = 'coffee'

      options.reporters.push('teamcity') if config.test.teamcity

      orig_stdout = process.stdout.write
      orig_stderr = process.stderr.write
      stdout = []
      process.stdout.write = (out) =>
        for line in out.replace(/\s+$/, '').split '\n'
          stdout.push line

      process.stderr.write = (out) =>
        @error out

      karma.server.start options, (exit_code) =>
        finish()

      unless config.singleRun and not updated_file?
        @watch config.test.files, (err) =>
          @error(err) if err
    catch err
      @error err
      finish()

  wrapError: (inf) ->
    unless inf and typeof inf is 'object' and inf.title? and inf.description?
      return super

    data =
      file:        if inf.file then @source.shortFile(inf.file) else 'test'
      title:       inf.title
      description: inf.description
    data.line = inf.line + 1 if inf.line?

    if inf.file and data.line
      if @watched[inf.file]?.data
        src = @watched[inf.file].data
      else
        try src = fs.readFileSync inf.file, encoding: 'utf8'
      if src and (lines = src.split('\n')).length and lines.length >= data.line
        data.lines =
          from: Math.max 1, data.line - 3
          to:   Math.min lines.length - 1, data.line * 1 + 3
        for line_literal, i in lines[data.lines.from - 1 .. data.lines.to - 1]
          data.lines[i + data.lines.from] = line_literal

    data

module.exports = Tester
