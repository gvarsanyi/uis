Outblock = require './outblock'


outblock = null

esc   = String.fromCharCode 27
first = true
hourglass = '⌛'

heads =
  css:  ['    ╔═╗╔═╗╔═╗  ', '    ║  ╚═╗╚═╗', '    ╚═╝╚═╝╚═╝']
  html: [' ╦ ╦╔╦╗╔╦╗╦    ', ' ╠═╣ ║ ║║║║', ' ╩ ╩ ╩ ╩ ╩╩═╝']
  js:   ['         ╦╔═╗  ', '         ║╚═╗', '       ╚═╝╚═╝']
  test: [' ╔╦╗╔═╗╔═╗╔╦╗  ', '  ║ ╠╣ ╚═╗ ║', '  ╩ ╚═╝╚═╝ ╩']
head_shown = {}

types =
  compiler:         'compile'
  concatenator:     'concat'
  deployer:         'deploy'
  minifiedDeployer: 'deploy-minified'
  loader:           'load'
  linter:           'lint'
  minifier:         'minify'

n_grouped = (n) ->
  _n = String(n).split('').reverse()
  n = ''
  for char, i in _n
    n = ',' + n if i % 3 is 0 and i
    n = char + n
  n

print_block = (push_x, push_y, title, inf, prev_inf) ->
  outblock
    .pos(push_x, push_y).bgcolor([36, 36, 36]).write(title, 20).reset()
    .pos(push_x, push_y + 1)

  if (inf.status? and inf.status < inf.count) or
  not prev_inf? or
  (prev_inf.status and prev_inf.status is prev_inf.count and not prev_inf.error)
    outblock.color([86, 86, 86]).write(hourglass, prev_inf).x(push_x).reset()

  has_n = ''
  if inf.status
    n = n_grouped(inf.status - (inf.warning?.length or 0) -
                  (inf.error?.length or 0))
    outblock.color([220, 255, 220]).write(n).reset()
    has_n = '+'
  if inf.warning?.length
    n = n_grouped inf.warning.length
    outblock.write(has_n).color([255, 236, 160]).write(n).reset()
    has_n = '+'
  if inf.error?.length
    n = n_grouped inf.error.length
    outblock.write(has_n).color([255, 127, 127]).write(n).reset()
    has_n = '+'
  if has_n
    plural = if inf.status > 1 then 's' else ''
    outblock.color([63, 63, 63]).write(' file' + plural).reset()

  if inf.size
    outblock
      .pos(push_x, push_y + 2).write(n_grouped inf.size)
      .color([63, 63, 63]).write(' b').reset()

shown_types = []

output = (stats) ->
  if (received_types = (name for name of stats)).length isnt shown_types
    if outblock?
#       outblock.setHeight received_types.length * 4
      outblock.clear()
      head_shown = {}
    else
      outblock = new Outblock process.stdout.rows - 1 # received_types.length * 4
      outblock.reset()
    shown_types = received_types

  push_y = 0
  for name, repo of {css: stats.css, html: stats.html, js: stats.js, test: stats.test}
    if repo
      prev_inf = null
      unless head_shown[name]?
        outblock
          .pos(0, push_y).bgcolor([36, 36, 36]).write(heads[name][0]).reset()
          .pos(0, push_y + 1).write(heads[name][1])
          .pos(0, push_y + 2).write(heads[name][2])
        head_shown[name] = true

      push_x = 15
      for type, inf of repo
        print_block push_x, push_y, types[type], inf, prev_inf
        push_x += 20
        prev_inf = inf
      push_y += 4


module.exports = output
