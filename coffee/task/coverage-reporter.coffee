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

    # test.coverage is falsy or a dictionary: {warningBar: 60, errorBar: 8-}
    if config.test.coverage
      default_bars = {warningBar: 80, errorBar: 60}
      unless typeof config.test.coverage is 'object'
        config.test.coverage =
          warningBar: default_bars.warningBar
          errorBar:   default_bars.errorBar
      for type in ['warningBar', 'errorBar']
        if isNaN Number String val = config.test.coverage[type]
          config.test.coverage[type] = default_bars[type]
        config.test.coverage[type] = Math.min 100, (Math.max 0, Number config.test.coverage[type])
      if config.test.coverage.errorBar > config.test.coverage.warningBar
        config.test.coverage.warningBar = config.test.coverage.errorBar
      if config.test.coverage.warningBar + config.test.coverage.errorBar is 0
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
                  if statements < config.test.coverage.warningBar
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

                if report.all?.statements and report.all.statements < config.test.coverage.warningBar
                  @[if report.all.statements < config.test.coverage.errorBar or lowest[0].statements < config.test.coverage.errorBar then 'error' else 'warning']
                    title: 'Low test coverage'
                    description: report.all.statements + '% of all statements' +
                                 ' covered. ' + desc
                    table: {data: rows, columns: cols}
                else
                  @[if lowest[0].statements < config.test.coverage.errorBar then 'error' else 'warning']
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
          compileCoffee: false
          reporters: [{type: 'html', dir: dir + 'html/'}
                      {type: 'text', dir: dir + 'text/', file: 'coverage.txt'}]

        if config.test.teamcity
          options.coverageReporter.reporters.push type: 'teamcity'

      karma.server.start options, (exit_code) =>
        finish()
    catch err
      @error err
      finish()

  wrapError: (inf) =>
    unless inf and typeof inf is 'object' and inf.title? and inf.description?
      return super
    inf

module.exports = CoverageReporter
