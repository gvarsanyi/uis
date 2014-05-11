karma = require 'karma'

Task      = require '../task'
config    = require '../config'
messenger = require '../messenger'


class Tester extends Task
  watchedFileChanged: (event, file) =>
    if file.substr(0, @source.projectPath.length) is @source.projectPath
      file = file.substr @source.projectPath.length + 1

    messenger.note 'updated: ' + file
    @work =>
      if config.output is 'fancy'
        messenger.sendStats()
      else
        messenger.sendState 'tester', 1, @error(), @warning(), []

  work: (callback) => @clear =>
    @status 0

    finish = (err) =>
      process.stdout.write = orig_stdout if orig_stdout
      process.stderr.write = orig_stderr if orig_stdout

      for line, i in stdout
        if (index = line.indexOf 'PhantomJS 1.9.7 (Linux): Executed ') > -1
          @result line.substr index + 24
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

      @warning(warning) if warning
      @error(err) if err
      @status 1
      callback? err

    try
      options =
        autoWatch:     false
        browsers:      ['PhantomJS']
        colors:        false
        files:         [config.js.deploy or config.js.deployMinified].concat config.js.test.files
        frameworks:    ['jasmine']
        logLevel:      'WARN'
        preprocessors: {}
        reporters:     ['spec']
        singleRun:     true
        specReporter: suppressPassed: true

      options.preprocessors[config.js.test.files] = 'coffee'

      options.reporters.push('teamcity') if config.js.test.teamcity

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

      @watch config.js.test.files, (err) =>
        @error(err) if err
    catch err
      finish err

  wrapError: (inf) ->
    unless inf and typeof inf is 'object' and inf.title? and inf.description?
      return super

    file:        inf.file or 'test'
    title:       inf.title
    description: inf.description

module.exports = Tester
