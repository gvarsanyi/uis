fs     = require 'fs'

glob   = require 'glob'
karma  = require 'karma'

Task   = require '../task'
config = require '../config'


class CoverageReporter extends Task
  double_dec = (n) ->
    n = String n
    if n.indexOf('.') is -1
      n += '.00'
    else
      parts = n.split '.'
      while parts[1].length < 2
        parts[1] += '0'
      parts[1] = parts[1].substr 0, 2
      n = parts.join '.'
    n

  name: 'coverageReporter'

  constructor: ->
    super

    if config.test.coverage
      unless typeof config.test.coverage is 'object'
        config.test.coverage = bar: 80
      else if isNaN Number String config.test.coverage.bar
        config.test.coverage.bar = 80
      else
        config.test.coverage.bar = Math.min 100, config.test.coverage.bar
        config.test.coverage.bar = Math.max 0, config.test.coverage.bar
        if config.test.coverage.bar is 0
          config.test.coverage = false

  condition: =>
    config.test.coverage and
    !!config[@source.name].files and
    @source.tasks.filesLoader.count() and
    not @source.tasks.tester.warning()?.length

  size: =>
    @_result or {}

  work: => @preWork (args = arguments), (callback) =>
    finished = false
    finish = =>
      return if finished
      finished = true

      glob @source.repoTmp + 'coverage/text/**/coverage.txt', (err, files) =>
        if err
          @error err
          callback()
        else unless files.length
          @error 'coverage output file generation failed'
          callback()
        else if files.length > 1
          @error 'coverage output file generation ambiguity'
          callback()
        else
          fs.readFile files[0], encoding: 'utf8', (err, data) =>
            if err
              @error err
              callback()
            else
              report = {files: {}, dirs: {}}
              lowest = []
              dir = null
              for line in data.split '\n' when line.substr(0, 4) isnt 'File' and line[0] isnt '-'
                parts = line.split ' | '
                [statements, branches, functions, lines] = for item in parts[1 .. 4]
                  Number item.replace('|', '').trim()
                info = {statements, branches, functions, lines}
                if line.substr(0, 6) is '      '
                  file = dir + parts[0].trim()
                  report.files[file] = info
                  if statements < config.test.coverage.bar
                    lowest.push {file, statements}
                else if line.substr(0, 3) is '   '
                  dir = parts[0].trim()
                  report.dirs[dir] = info
                else if line.substr(0, 9) is 'All files'
                  report.all = info

              if lowest.length
                lowest.sort (a, b) ->
                  return 1 if a.statements > b.statements
                  -1

                rows = []
                for item in lowest
                  rows.push [item.file, double_dec(item.statements) + '%']

                desc = lowest.length + ' file' +
                       (if lowest.length > 1 then 's' else '') + ' do' +
                       (if lowest.length > 1 then '' else 'es') +
                       ' not meet the bar.'
                cols = [{title: 'Files not meeting the bar'}
                        {align: 'right'}]

                if report.all?.statements and report.all.statements < config.test.coverage.bar
                  @warning
                    title: 'Low test coverage'
                    description: report.all.statements + '% of all statements' +
                                 ' covered. ' + desc
                    table: {data: rows, columns: cols}
                else
                  @warning
                    description: report.all.statements + '% of statements ' +
                                 ' covered overall, but ' + desc
                    table: {data: rows, columns: cols}

              @result report
              callback()

    try
      tester = @source.tasks.tester

      options = tester.getDefaultOptions 'dot', tester.getCloneDeployment(), config.test.files

      for test_file in config.test.files when test_file.indexOf('.coffee') > -1
        options.preprocessors[test_file] = 'coffee'

      if config.test.coverage
        options.reporters.push 'coverage'

        for item in config.test.repos when not (item.thirdParty or item.testOnly)
          list = item.repo
          list = [list] unless typeof list is 'object'
          dir = @source.repoTmp + 'clone' + @source.projectPath + '/'
          for repo in list
            options.preprocessors[dir + repo] = 'coverage'

        dir = @source.repoTmp + 'coverage/'
        options.coverageReporter =
          instrumenter: '**/*.coffee': 'istanbul'
          reporters: [{type: 'html', dir: dir + 'html/'}
                      {type: 'text', dir: dir + 'text/', file: 'coverage.txt'}]

        if config.test.teamcity
          options.coverageReporter.reporters.push type: 'teamcity'

      karma.server.start options, (exit_code) =>
        @error('Karma coverage failed, exit code: ' + exit_code) if exit_code > 0
        finish()
    catch err
      @error err
      finish()

  wrapError: (inf) =>
    unless inf and typeof inf is 'object' and inf.title? and inf.description?
      return super
    inf

module.exports = CoverageReporter
