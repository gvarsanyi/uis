fs     = require 'fs'

glob   = require 'glob'
karma  = require 'karma'

Task   = require '../task'
config = require '../config'


class CoverageReporter extends Task
  name: 'coverageReporter'

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

      glob @source.tmp + '.coverage/text/**/coverage.txt', (err, files) =>
        if err
          @error err
          callback()
        else unless files.length
          @error 'coverage output file generation failed'
          callback()
        else if files.length > 1
          console.log files
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
                  if statements < 80
                    lowest.push {file, statements}
                else if line.substr(0, 3) is '   '
                  dir = parts[0].trim()
                  report.dirs[dir] = info
                else if line.substr(0, 9) is 'All files'
                  report.all = info

              if report.all?.statements and report.all.statements < 80
                lowest.sort (a, b) ->
                  return 1 if a.statements > b.statements
                  -1
                msg = 'Files not meeting the 80% bar:'
                if lowest.length > 10
                  lowest = lowest[0 .. 9]
                  msg = 'Files not meeting the 80% bar - 10 lowest coverages:'
                for item in lowest
                  msg += '\n  ' + item.file + ' (' + item.statements + '%)'
                @[if report.all.statements < 60 then 'error' else 'warning']
                  title: 'Low test coverage'
                  description: report.all.statements + '% of all statements covered.\n\n' + msg

              for file, info of report.files when info.statements < 80
                @[if info.statements < 60 then 'error' else 'warning']
                  file: file
                  title: 'Low test coverage'
                  description: info.statements + '% of statements covered.'

              @result report
              callback()

    try
      unless config.test.files and typeof config.test.files is 'object'
        config.test.files = [config.test.files]

      tester = @source.tasks.tester

      options = tester.getDefaultOptions 'dot', tester.getCloneDeployment(), config.test.files

      for test_file in config.test.files when test_file.indexOf('.coffee') > -1
        options.preprocessors[test_file] = 'coffee'

      if config.test.coverage
        options.reporters.push 'coverage'
        for item in config.test.repos when not (item.thirdParty or item.testOnly)
          list = item.repo
          list = [list] unless typeof list is 'object'
          for repo in list
            options.preprocessors[@source.repoTmp + 'clone' + @source.projectPath + '/' + repo] = 'coverage'
        options.coverageReporter = reporters: [
          {type: 'html', dir: @source.tmp + '.coverage/html/'}
          {type: 'lcovonly', dir: @source.tmp + '.coverage/lcov/'}
          {type: 'text', dir: @source.tmp + '.coverage/text/', file: 'coverage.txt'}]
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
