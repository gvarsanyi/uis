coffeelint = require 'coffeelint'
jslint     = require 'jslint'

FilesLinter = require '../files-linter'


class JsFilesLinter extends FilesLinter
  workFile: => @preWorkFile arguments, (source, callback) =>
    try
      unless source.data?
        throw new Error '[' + @constructor.name + '] Missing source: ' + source.path

      if source.compilable
        for msg in coffeelint.lint source.data
          @warning msg, source
      else
        (worker = jslint.load 'latest') source.data
        for msg in worker.errors
          @warning msg, source
    catch err
      @error err, source

    callback()

  wrapError: (inf, source) =>
    # Example for inf
    # { name: 'no_unnecessary_fat_arrows',
    #   level: 'warn',
    #   message: 'Unnecessary fat arrow',
    #   description: 'Disallows defining functions with fat arrows when `this`\nis not used within the function.',
    #   lineNumber: 102,
    #   rule: 'no_unnecessary_fat_arrows' }
    data = super

    if source?.compilable
      data.line = Number(inf.lineNumber) if inf.lineNumber

      if inf.message
        data.title = inf.message
        if inf.name
          data.title += ' (' + inf.name + ')'
      else if inf.name
        data.title = inf.name

      data.description = inf.description if inf.description

      if data.line and source.data
        line = inf.lineNumber - 1
        if (lines = source.data.split('\n')).length and lines.length >= line
          data.lines =
            from: Math.max 1, line - 2
            to:   Math.min lines.length - 1, line * 1 + 4
          for line_literal, i in lines[data.lines.from - 1 .. data.lines.to - 1]
            data.lines[i + data.lines.from] = line_literal

    data

module.exports = JsFilesLinter
