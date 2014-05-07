RgbAnsi = require './rgb-ansi'


class Outblock
  esc = String.fromCharCode 27
  sequence = (param, modifier='m') ->
    process.stdout.write esc + '[' + param + modifier

  constructor: (@height) ->
    for i in [0 ... @height]
      process.stdout.write '\n'

  reset: =>
    sequence 0
    @

  setHeight: (new_height) =>
    if new_height < @height
      sequence @height - new_height, 'A'
    else if new_height > @height
      for i in [0 ... @height - new_height]
        process.stdout.write '\n'
    @height = new_height
    @

  clear: =>
    sequence @height, 'A'
    for [0 ... @height]
      process.stdout.write ((' ' for [0 ... process.stdout.columns]).join '') + '\r\n'
    @_x = @_y = 0
    @

  bold: =>
    sequence 1
    @

  nobold: =>
    sequence 21
    @

  underline: =>
    sequence 4
    @

  nounderline: =>
    sequence 24
    @

  color: (rgb) =>
    sequence '38;5;' +  RgbAnsi::rgb256 rgb
    @

  nocolor: =>
    sequence 39
    @

  bgcolor: (rgb) =>
    sequence '48;5;' +  RgbAnsi::rgb256 rgb
    @

  nobgcolor: =>
    sequence 49
    @

  x: (@_x) =>
    @

  y: (@_y) =>
    @

  pos: (x, y) =>
    @x x
    @y y
    @

  write: (msg, clear) =>
    x = @_x
    y = @_y

    if y >= @height or y < 0 or x >= limit = process.stdout.columns
      return @

    if clear > 1 or clear is 1
      if clear > msg.length
        msg += (' ' for i in [0 ... clear - msg.length]).join ''
      else if clear < msg.length
        msg = msg.substr 0, clear

    if x < 0
      msg = msg.substr 0 - x

    if x + msg.length > limit
      msg = msg.substr 0, limit - x

    msg = msg.replace esc, ' '
    @_x += msg.length

    diff = @height - y
    sequence diff, 'A'
    sequence(x, 'C') if x
    process.stdout.write msg + '\r'
    sequence diff, 'B'
    @

module.exports = Outblock
