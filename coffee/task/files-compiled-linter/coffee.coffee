coffeelint = require 'coffeelint'

FilesCompiledLinter = require '../files-compiled-linter'


class CoffeeFilesLinter extends FilesCompiledLinter
  workFile: => @preWorkFile arguments, (source, callback) =>
    try
      unless (src = source.data)?
        throw new Error '[CoffeeFilesLinter] Missing source: ' + source.path

      for msg in coffeelint.lint src
        if msg.level is 'error'
          @error msg
        else
          @warning msg
    catch err
      @error err

    callback()

  wrapError: (inf) =>
    # Example for inf
    # { name: 'no_unnecessary_fat_arrows',
    #   level: 'warn',
    #   message: 'Unnecessary fat arrow',
    #   description: 'Disallows defining functions with fat arrows when `this`\nis not used within the function.',
    #   lineNumber: 102,
    #   rule: 'no_unnecessary_fat_arrows' }
    data = super

    data.line = Number(inf.lineNumber) if inf.lineNumber

    if inf.message
      data.title = inf.message
      if inf.name
        data.title += ' (' + inf.name + ')'
    else if inf.name
      data.title = inf.name

    data.description = inf.description if inf.description

    if data.line and src = @source.tasks.loader.result()
      line = inf.lineNumber - 1
      if (lines = src.split('\n')).length and lines.length >= line
        data.lines =
          from: Math.max 1, line - 2
          to:   Math.min lines.length - 1, line * 1 + 4
        for line_literal, i in lines[data.lines.from - 1 .. data.lines.to - 1]
          data.lines[i + data.lines.from] = line_literal

    data

module.exports = CoffeeFilesLinter
