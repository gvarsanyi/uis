
class RgbAnsi
  ansi_colors16 = [
    [0, 0, 0]
    [205, 0, 0]
    [0, 205, 0]
    [205, 205, 0]
    [0, 0, 238]
    [205, 0, 205]
    [0, 205, 205]
    [229, 229, 229]
    [127, 127, 127]
    [255, 0, 0]
    [0, 255, 0]
    [255, 255, 0]
    [92, 92, 255]
    [255, 0, 255]
    [0, 255, 255]
    [255, 255, 255]
  ]
  ansi_colors8 = ansi_colors16[0 .. 7]

  rgb_distance = (rgb1, rgb2)->
    [r, g, b] = rgb1
    [s, h, c] = rgb2
    r -= s
    g -= h
    b -= c
    r * r + g * g + b * b

  # Convert an RGB color to 8 or 16 color ANSI graphics.
  rgb_reduce = (rgb, mode) ->
    colors = if mode is 16 then ansi_colors16 else ansi_colors8
    for color, i in colors
      if distance = rgb_distance(color, rgb) < min_distance or not min_distance?
        min_distance = distance
        closest = i
    i

  validate_rgb = (rgb, callback) ->
    unless rgb?.length is 3 and typeof rgb is 'object'
      throw new Error 'Invalid parameters: ' + (String(rgb) or 'no parameters')

    [r, g, b] = for item in rgb
      unless (n = Number item) > 1 or n is 1 or n is 0
        throw new Error '"' + item + '" is not a valid number (range: 0 .. 255)'
      n

    callback r, g, b

  # Convert an RGB color to 8 color ANSI graphics.
  rgb8: (rgb) -> validate_rgb rgb, (r, g, b) ->
    rgb_reduce [r, g, b], 8

  # Convert an RGB color to 16 color ANSI graphics.
  rgb16: (rgb) -> validate_rgb rgb, (r, g, b) ->
    rgb_reduce [r, g, b], 16

  # Convert an RGB color to 256 color ANSI graphics.
  rgb256: (rgb) -> validate_rgb rgb, (r, g, b) ->
    grey = false
    poss = true
    step = 2.5

    while poss # As long as the color could be grey scale
      if r < step or g < step or b < step
        grey = r < step and g < step and b < step
        poss = false

      step += 42.5

    if grey
      return 232 + Math.floor (r + g + b) / 33

    color = 16
    for [val, mod] in [[r, 36], [g, 6], [b, 1]]
      color += Math.floor(6 * val / 256) * mod

    color

module.exports = RgbAnsi
