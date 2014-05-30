fs     = require 'fs'

karma  = require 'karma'

Task   = require '../task'
config = require '../config'


class Tester extends Task
  name: 'tester'

  constructor: ->
    super

    @fullTestDone = false

    # test.files is an array
    unless config.test.files and typeof config.test.files is 'object'
      config.test.files = [config.test.files]

  condition: =>
    !!config[@source.name].files and @source.tasks.filesLoader?.count()

  followUp: (node) =>
    @source.tasks.coverageReporter?.work node

  getCloneDeployment: =>
    deployment = []
    for item in config.test.repos
      list = item.repo
      list = [list] unless typeof list is 'object'
      for repo in list
        deployment.push @source.repoTmp + 'clone' + @source.projectPath + '/' + repo
    deployment

  getDefaultOptions: (reporter, deployment, test_files) =>
    autoWatch:     false
    browsers:      ['PhantomJS']
    colors:        false
    files:         deployment.concat test_files
    frameworks:    ['jasmine']
    logLevel:      'ERROR'
    preprocessors: {}
    reporters:     [reporter]
    singleRun:     true

  size: =>
    @_result or 0

  work: => @preWork (args = arguments), (callback) =>
    if @fullTestDone
      if typeof args[0] is 'object' and args[0].file and @_watched[args[0].file]
        updated_file = args[0].file

    finished = false
    finish = =>
      return if finished
      @fullTestDone = true
      finished = true

      process.stdout.write = orig_stdout if orig_stdout
      process.stderr.write = orig_stderr if orig_stderr

      for line, i in stdout or []
        if line.substr(0, 10) is 'PhantomJS ' and (index = line.indexOf ') ERROR') > -1
          @error {file: 'PhantomJS error', title: 'Failed to run tests', description: 'Tip: check if all your it() functions are inside a describe() function'}
          return callback()

        if line.substr(0, 10) is 'PhantomJS ' and (index = line.indexOf '): Executed ') > -1 and
        result = Number line.substr(index + 12).split(' ')[2]
          @result result
        else if line.substr(0, 6) is '    ✗ '
          @warning(warning) if warning
          warning =
            file:  stdout[i - 1].trim()
            title: line.substr 6
        else if line.substr(0, 8) is '      ✗ '
          @warning(warning) if warning
          warning =
            file:  stdout[i - 2].trim() + ': ' + stdout[i - 1].trim()
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
        else if line.indexOf('##teamcity') > -1
          console.log line

        if config.test.log
          for line, i in stdout or []
            console.log 'karma output [' + i + ']', line

      @warning(warning) if warning
      callback()

    try
      testables = if updated_file then [updated_file] else config.test.files

      options = @getDefaultOptions 'spec', @getCloneDeployment(), testables
      options.specReporter = suppressPassed: true

      delete coverageReport

      if updated_file and updated_file.indexOf('.coffee') > -1
        options.preprocessors[updated_file] = 'coffee'
      else
        for test_file in testables when test_file.indexOf('.coffee') > -1
          options.preprocessors[test_file] = 'coffee'

        if config.test.coverage
          @source.tasks.coverageReporter?.addCoverageOptions options
          @coverageReport = true

      if config.test.teamcity and not updated_file
        options.reporters.push 'teamcity'

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

  wrapError: (inf) =>
    unless inf and typeof inf is 'object' and inf.title? and inf.description?
      return super

    data =
      file:        if inf.file then @source.shortFile(inf.file) else 'test'
      title:       inf.title
      description: inf.description
    data.line = inf.line + 1 if inf.line?

    if inf.file and data.line
      if @_watched?[inf.file]?.data
        src = @_watched?[inf.file].data
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
