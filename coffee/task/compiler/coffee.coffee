coffee = require 'coffee-script'

Compiler = require '../compiler'


class CoffeeCompiler extends Compiler
  compileSrc: (src) ->
    coffee.compile src, bare: true

  work: (callback) => @clear =>
    @status 0

    try
      unless (src = @source.tasks.loader.result())?
        throw new Error '[CoffeeCompiler] Missing source'

      @result coffee.compile src, bare: true
    catch err
      @error err

    @status 1
    callback? err

  wrapError: (inf) =>
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
    (to = Number inf.location.last_line) and
    not isNaN(from) and not isNaN(to) and
    from >= to and from >= 0 and
    (src = @source.tasks.loader.result()) and
    (lines = src.split('\n')).length and
    lines.length > to
      data.line = (n for n in [from + 1 .. to + 1])
      data.line = data.line[0] if data.line.length is 1
      data.lines =
        from: Math.max 1, from - 2
        to:   Math.min lines.length - 1, to * 1 + 4
      for line_literal, i in lines[data.lines.from - 1 .. data.lines.to - 1]
        data.lines[i + data.lines.from] = line_literal

    data

module.exports = CoffeeCompiler
