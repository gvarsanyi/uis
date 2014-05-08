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
  working = (inf.status? and inf.status < inf.count) or
            not prev_inf? or
            (prev_inf.status and
             prev_inf.status is prev_inf.count and
             not prev_inf.error)

  if inf.status? or working
    outblock.bgcolor([36, 36, 36])
  else
    outblock.color([50, 50, 50]).bgcolor([12, 12, 12])

  outblock
    .pos(push_x, push_y).write(title, 20).reset()
    .pos(push_x, push_y + 1).write('', 20)
    .pos(push_x, push_y + 2).write('', 20)
    .pos(push_x, push_y + 1)

  if working
    outblock.color([86, 86, 86]).write(hourglass, prev_inf).x(push_x).reset()

  has_n = ''
  if inf.status
    n = n_grouped(inf.status - (inf.warning?.length or 0) -
                  (inf.error?.length or 0))
    outblock.color([220, 220, 220]).write(n)
    has_n = '+'
  if inf.warning?.length
    n = n_grouped inf.warning.length
    outblock.write(has_n).color([255, 159, 63]).write(n)
    has_n = '+'
  if inf.error?.length
    n = n_grouped inf.error.length
    outblock.write(has_n).color([255, 20, 20]).write(n)
    has_n = '+'
  if has_n
    plural = if inf.status > 1 then 's' else ''
    outblock.color([63, 63, 63]).write(' file' + plural)
  if inf.watched
    outblock
      .color([63, 63, 63]).write(' + ')
      .reset().write(n_grouped inf.watched)
      .color([63, 63, 63]).write(' inc')

  if inf.size
    outblock
      .pos(push_x, push_y + 2).color([160, 160, 160]).write(n_grouped inf.size)
      .color([63, 63, 63]).write(' b').reset()
  else if inf.status is inf.count and not inf.error?.length and
          title.indexOf('deploy') > -1 and inf.updatedAt
    try
      if inf.updatedAt > 1000000 and (t = new Date inf.updatedAt)
        hm   = t.getHours() + ':' + (if (m = t.getMinutes()) > 9 then m else '0' + m)
        sec  = ':' + if (s = t.getSeconds()) > 9 then s else '0' + s
        tsec = '.' + Math.floor t.getMilliseconds() / 100
        outblock
          .pos(push_x, push_y + 2).color([63, 63, 63]).write('@ ')
          .color([160, 160, 160]).write(hm)
          .color([79, 79, 79]).write(sec)
          .color([47, 47, 47]).write(tsec)

  outblock.reset()

shown_types = []

output = (stats) ->
#   if stats.html?.minifiedDeployer?.error
#     console.log stats.html.minifiedDeployer?.error
#     process.exit 1

  if (received_types = (name for name of stats)).length isnt shown_types.length
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
