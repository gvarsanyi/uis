coffee = require 'coffee-script'

FilesCompiler = require '../files-compiler'


class FilesCoffeeCompiler extends FilesCompiler
  workFile: => @preWorkFile arguments, (source, callback) =>
    try
      unless source.data?
        throw new Error '[FilesCoffeeCompiler] Missing source: ' + source.path

      source[@sourceProperty] = coffee.compile source.data, bare: true
    catch err
      @error err, source

    callback()

  wrapError: (inf, source) =>
    # Example for inf
    # { location: {
    #     first_line: 4264,
    #     first_column: 0,
    #     last_line: 4264,
    #     last_column: 7 },
    #   code: '...' }
    data = super

    data.title = inf.constructor.name if inf.constructor.name
    data.description = data.description.split('\n')[0].split(':')[4 ..].join ':'

    if (from = Number inf.location?.first_line) and
    (to = Number inf.location?.last_line or inf.location?.first_line) and
    not isNaN(from) and not isNaN(to) and
    from >= to and from >= 0 and
    source.data and
    (lines = source.data.split('\n')).length and
    lines.length > to
      data.line = (n for n in [from + 1 .. to + 1])
      data.line = data.line[0] if data.line.length is 1
      data.lines =
        from: Math.max 1, from - 2
        to:   Math.min lines.length - 1, to * 1 + 4
      for line_literal, i in lines[data.lines.from - 1 .. data.lines.to - 1]
        data.lines[i + data.lines.from] = line_literal

    if @source.name is 'test' and not source.options.testOnly
      data.muted = true

    data

module.exports = FilesCoffeeCompiler
