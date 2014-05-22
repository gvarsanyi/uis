Outblock = require '../outblock'
ngroup   = require '../ngroup'
plural   = require '../plural'
stats    = require '../../stats'
types    = require '../stat-types'

console.log ''

outblock = null

esc       = String.fromCharCode 27
first     = true
enter     = '↲'
hourglass = '⌛'

colors =
  err:   [255, 20, 20]
  faint: [63, 63, 63]
  warn:  [255, 159, 63]
  white: [220, 220, 220]


heads =
  css:  ['    ╔═╗╔═╗╔═╗  ', '    ║  ╚═╗╚═╗', '    ╚═╝╚═╝╚═╝']
  html: [' ╦ ╦╔╦╗╔╦╗╦    ', ' ╠═╣ ║ ║║║║', ' ╩ ╩ ╩ ╩ ╩╩═╝']
  js:   ['         ╦╔═╗  ', '         ║╚═╗', '       ╚═╝╚═╝']
  test: [' ╔╦╗╔═╗╔═╗╔╦╗  ', '  ║ ╠╣ ╚═╗ ║', '  ╩ ╚═╝╚═╝ ╩']

print_block = (push_x, push_y, title, inf, prev_inf) ->
  working = not inf.done and
            (inf.status < inf.count or not prev_inf? or
             (prev_inf.done and not prev_inf.error))

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

  if inf.error?.length

    outblock.color(colors.err).write(ngroup inf.error.length)
      .color(colors.faint).write(plural ' error', inf.error.length)
  else
    if inf.status
      if title in ['test', 'coverage']
        if inf.warning?.length
          outblock.color(colors.warn).write(ngroup inf.warning.length)
            .color(colors.faint).write(plural ' warning', inf.warning.length)
        else if title is 'test'
          outblock.color(colors.white).write(ngroup inf.size)
            .color(colors.faint).write(plural(' test', inf.size) + ' passed')
        else # coverage
          color = colors.white
          if inf.size.all.statements < (config.test?.coverage?.bar or 80)
            color = colors.warn
          outblock.color(color).write(inf.size.all.statements + '%')
            .color(colors.faint).write(' of statements')
      else
        n = ngroup inf.status - (inf.warning?.length or 0)
        outblock.color(colors.white).write(n)
        if inf.warning?.length
          n = ngroup inf.warning.length
          outblock.write('+').color(colors.warn).write(n)
        outblock.color(colors.faint).write(plural ' file', inf.status)
  if inf.watched and title isnt 'test'
    outblock
      .color(colors.faint).write(' + ')
      .reset().write(ngroup inf.watched)
      .color(colors.faint).write(' inc')

  if inf.size and title isnt 'coverage' and title isnt 'test'
    outblock
      .pos(push_x, push_y + 2).color([160, 160, 160]).write(ngroup inf.size)
      .color(colors.faint).write(' b').reset()
# TODO: startedAt, finishedAt
#   else if inf.status is inf.count and not inf.error?.length and
#           title.indexOf('deploy') > -1 and inf.updatedAt
#     try
#       if inf.updatedAt > 1000000 and (t = new Date inf.updatedAt)
#         hm   = t.getHours() + ':' + (if (m = t.getMinutes()) > 9 then m else '0' + m)
#         sec  = ':' + if (s = t.getSeconds()) > 9 then s else '0' + s
#         tsec = '.' + Math.floor t.getMilliseconds() / 100
#         outblock
#           .pos(push_x, push_y + 2).color(colors.faint).write('@ ')
#           .color([160, 160, 160]).write(hm)
#           .color([79, 79, 79]).write(sec)
#           .color([47, 47, 47]).write(tsec)

  outblock.reset()

shown      = {}
head_shown = {}


module.exports.update = (update) ->
  new_sum = orig_sum = (name for name of shown).length
  for name of stats.data
    new_sum += 1 unless shown[name]
  if orig_sum isnt new_sum
    shown[name] = true
    if outblock?
      outblock.setHeight new_sum * 4
      head_shown = {}
    else
      outblock = new Outblock process.stdout.rows - 1
#       outblock = new Outblock new_sum * 4

  push_y = 0
  for name, repo of {css: stats.data.css, html: stats.data.html, js: stats.data.js, test: stats.data.test}
    if repo
      prev_inf = null
      unless head_shown[name]?
        outblock
          .pos(0, push_y).bgcolor([36, 36, 36]).write(heads[name][0]).reset()
          .pos(0, push_y + 1).write(heads[name][1])
          .pos(0, push_y + 2).write(heads[name][2])
        head_shown[name] = true

      push_x = 15
      for type, inf of repo when inf.count > 0
        print_block push_x, push_y, types[type] or type, inf, prev_inf
        push_x += 20
        prev_inf = inf
    push_y += 4


escaped_out = (msg) ->
  out = String(msg).trim()
    .split('\n').join(enter)
    .split(esc).join('\\0')
    .substr(0, process.stdout.columns - 10)
  process.stdout.write (' ' for i in [0 ... process.stdout.columns]).join('')
  process.stdout.write '\r' + out + '\r'

module.exports.log = (msg) ->
  escaped_out '[' + msg.repo + '] ' + msg.msg

module.exports.error = (msg) ->
  escaped_out '[' + msg.repo + '] ERROR ' + msg.msg
