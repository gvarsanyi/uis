child_process = require 'child_process'
fs            = require 'fs'
path          = require 'path'

minimatch     = require 'minimatch'

Task          = require '../task'
config        = require '../config'
messenger     = require '../messenger'


class Tester extends Task
  name: 'tester'

  constructor: ->
    super

    @fullTestDone = false

    # test.files is an array
    unless config.test.files and typeof config.test.files is 'object'
      config.test.files = [config.test.files]
    unless config.test.helpers and typeof config.test.helpers is 'object'
      config.test.helpers = [config.test.helpers]

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

    pre_callback = =>
      code = if @_error?.length or @_warning?.length then 1 else 0
      messenger.sendTestExitCode code
      callback()

    finished = false
    exited   = false
    finish = =>
      return if finished
      finished = true

      get_tabs = (line) ->
        tab = 0
        while line.substr(0, 2) is '  '
          tab += 1
          line = line.substr 2
        tab

      titles = []
      for line, i in stdout or []
        if line.substr(0, 10) is 'PhantomJS ' and (index = line.indexOf ') ERROR') > -1
          if stdout[i + 1].substr(0, 2) is '  '
            inf = {title: 'Failed to run tests', description: ''}
            for following_line in stdout[i + 1 ...]
              break unless following_line.trim()
              if following_line.substr(0, 5) is '  at '
                inf.file = following_line.substr 5
              else
                inf.description += following_line + '\n'
            @error inf
          else
            @error {file: 'PhantomJS error', title: 'Failed to run tests', description: 'Tip: check if all your it() functions are inside a describe() function'}
          if config.test.log
            console.log(line) for line in stdout
          return pre_callback()

        if tab = get_tabs line # has at least 1 tab
          titles = titles[0 ... tab - 1]
          titles.push line.substr tab * 2

        if line.substr(0, 10) is 'PhantomJS ' and (index = line.indexOf '): Executed ') > -1 and
        result = Number line.substr(index + 12).split(' ')[2]
          @result result
        else if tab and titles[titles.length - 1].substr(0, 2) is '✗ '
          @warning(warning) if warning
          warning = 
            file:  titles[0 ... titles.length - 1].join ' / '
            title: titles.pop().substr 2
        else if line.substr(0, 1) is '\t' and line.trim() and warning
          if warning.description
            warning.description += '\n' + line.trim()
          else
            warning.description = line.trim()
        else unless line # skip
        else if line.substr(0, 9) is 'LOG LOG: '
          console.log '[test console.log] ' + line.substr 9
        else if line.substr(0, 11) is 'ERROR LOG: '
          console.error '[test console.error] ' + line.substr 11
        else if line.substr(0, 29) is 'ERROR [preprocessor.coffee]: '
          inf =
            description: line.substr 29
            title:       'Compilation Error'
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
        for line, i in stdout or [] when String(line).trim()
          console.log 'karma output [' + i + ']', line

      @warning(warning) if warning
      unless @_error?.length or @_warning?.length
        @fullTestDone = true
      pre_callback()

    array_match = (matchee) ->
      for file in config.test.files
        file = path.resolve file
        matchee = path.resolve matchee
        return true if minimatch matchee, file
      false

    try
      testables = (item for item in config.test.helpers or [])
      if updated_file and array_match updated_file
        testables.push updated_file
      else
        updated_file = null
        for file in config.test.files
          testables.push file

      options = @getDefaultOptions 'spec', @getCloneDeployment(), testables
      options.specReporter = suppressPassed: true

      delete coverageReport

      if updated_file and updated_file.indexOf('.coffee') > -1
        if config.test.helpers
          for file in config.test.helpers when file.indexOf('.coffee') > -1
            options.preprocessors[file] = 'coffee'
        options.preprocessors[updated_file] = 'coffee'
      else
        for test_file in testables when test_file.indexOf('.coffee') > -1
          options.preprocessors[test_file] = 'coffee'

        if config.test.coverage
          @source.tasks.coverageReporter?.addCoverageOptions options
          @coverageReport = true

      if config.test.teamcity and not updated_file
        options.reporters.push 'teamcity'

      karma = child_process.fork __dirname + '/../../resource/karma-wrapper.js',
                                 {cwd: @source.projectPath, silent: true}

      karma.on 'message', (msg) ->
        if msg is 'ready'
          karma.send options

      stdout = []
      karma.stdout.on 'data', (data) ->
        for line in String(data).replace(/\s+$/, '').split '\n'
          stdout.push line

      karma.on 'error', (err) ->
        if config.test.log
          console.error 'karma-wrapper error', err
        finish()

      karma.on 'close', (code, signal) ->
        if not exited and config.test.log and (code or signal)
          console.log 'karma-wrapper closed', code, signal or ''
        exited = true
        finish()

      karma.on 'exit', (code, signal) ->
        if not exited and config.test.log and (code or signal)
          console.log 'karma-wrapper exited', code, signal or ''
        exited = true
#         finish()

#       karma.on 'disconnect', ->
#         if config.test.log
#           console.log 'karma-wrapper disconnected'
#         finish()

      karma.stderr.on 'data', (data) =>
        console.error String data
        @error String data

      for delay in [1, 10, 50, 100, 200, 300, 500, 750, 1000]
        do (delay) ->
          setTimeout ->
            karma.send options
          , delay

      unless config.singleRun and not updated_file?
        files = (item for item in config.test.files)
        for file in config.test.helpers or []
          files.push file
        @watch files, (err) =>
          @error(err) if err
    catch err
      @error String err
      finish()

  wrapError: (inf) =>
    unless inf and typeof inf is 'object' and inf.title? and inf.description?
      return super

    data =
      file:        if inf.file then @source.shortFile(inf.file) else 'test'
      title:       inf.title
      description: String(inf.description or '').trim()
    data.line = inf.line + 1 if inf.line?

    if inf.file and data.line
      if @_watched?[inf.file]?.data
        src = @_watched?[inf.file].data
      else
        try src = fs.readFileSync inf.file, encoding: 'utf8'
      if src and (lines = String(src).split('\n')).length and lines.length >= data.line
        data.lines =
          from: Math.max 1, data.line - 3
          to:   Math.min lines.length - 1, data.line * 1 + 3
        for line_literal, i in lines[data.lines.from - 1 .. data.lines.to - 1]
          data.lines[i + data.lines.from] = line_literal

    data

module.exports = Tester
