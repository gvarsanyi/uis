ngroup = require '../ngroup'
types  = require '../stat-types'


###
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

  outblock.reset()###

last_state = {}

timestamp = ->
  fix = (n, digits=2) ->
    while String(n).length < digits
      n = '0' + digits
    n

  (t = new Date()).getHours() + ':' +
  fix(t.getMinutes()) + ':' +
  fix(t.getSeconds()) + '.' +
  fix(t.getMilliseconds(), 3)

icons =
  check:   '✔'
  error:   '✗'
  warning: '⚠'
  working: '⌛'

subitem = '↳'

print = (status, repo, msg...) ->
  icon   = ' ' + (icons[status] or ' ')
  output = if status is 'error' then 'error' else 'log'

  repo = ' [' + repo + ']'
  while repo.length < 7
    repo = ' ' + repo

  console[output] timestamp() + repo + icon, msg...

obj_to_str = (status, inf) ->
  unless inf.file
    '[' + status.toUpperCase() + '] ' + String(inf) + '\n'

  out = '[' + status.toUpperCase() + '] ' + inf.file +
        (if inf.line then ' @ line ' + inf.line else '') + '\n'

  indent = '  '

  if inf.lines
    for n in [inf.lines.from .. inf.lines.to]
      if inf.lines[n]?
        push = if String(n).length < String(inf.lines.to).length then ' ' else ''
        pre = indent
        if n is inf.line or (typeof inf.line is 'object' and n in [inf.line])
          pre = pre.split(' ').join('>')
        out += pre + '(' + n + ') ' + inf.lines[n] + '\n'

  if inf.title
    out += indent + inf.title + '\n'

  if inf.description
    out += indent + '  ' + subitem + ' ' +
           inf.description.split('\n').join('\n    ' + indent) + '\n'

  out

info_out = (status, inf) ->
  output = if status is 'error' then 'error' else 'log'

  console[output] ''
  for block in inf
    if block instanceof Array
      for part in block
        console[output] obj_to_str status, part
    else
      console[output] obj_to_str status, block

output = (stats) ->
  push_y = 0
  for name, repo of {css: stats.css, html: stats.html, js: stats.js, test: stats.test}
    if repo
      last_state[name] ?= {}

      for type, inf of repo
        state = null
        if inf.count
          if inf.status and inf.status is inf.count and last_state[name][type] isnt 'done'
            if inf.error?.length
              print 'error', name, types[type]
              info_out 'error', inf.error
              info_out('warning', inf.warning) if inf.warning?.length
            else if inf.warning?.length
              print 'warning', name, types[type]
              info_out 'warning', inf.warning
            else
              print 'check', name, types[type]

            last_state[name][type] = 'done'
          else if inf.status and inf.status isnt inf.count and last_state[name][type] isnt 'working'
            last_state[name][type] = 'working'

module.exports = output
