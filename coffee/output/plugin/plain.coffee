ngroup = require '../ngroup'
types  = require '../stat-types'


timestamp = ->
  fix = (n, digits=2) ->
    while String(n).length < digits
      n = '0' + n
    n

  (t = new Date()).getHours() + ':' +
  fix(t.getMinutes()) + ':' +
  fix(t.getSeconds()) + '.' +
  fix(t.getMilliseconds(), 3)

icons =
  start:   '⚐'
  check:   '✔'
  error:   '✗'
  warning: '⚠'
  working: '⌛'

subitem = '↳'

print = (status, repo, task, msg...) ->
  icon   = ' ' + (icons[status] or ' ')
  output = if status is 'error' then 'error' else 'log'

  repo = ' [' + repo + ']'
  while repo.length < 7
    repo = ' ' + repo

  console[output] timestamp() + repo + icon + ' ' + task, msg...

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

module.exports.update = (update) ->
  {error, warning} = update.stat

  done = update.stat.status and update.stat.status is update.stat.count
  error_state = 'start'
  error_state = 'check' if done
  error_state = 'warning' if warning
  error_state = 'error' if error

  if done or error or warning
    msg = ''
    if error
      msg += ': ' + error.length + ' error' + if error.length > 1 then 's' else ''
    if warning?
      msg += if msg then ', ' else ': '
      msg += warning.length + ' warning' + if warning.length > 1 then 's' else ''
#     msg += ' ' + JSON.stringify update

    print error_state, update.repo, types[update.task] or update.task, msg

    if error?
      info_out 'error', error

    if warning?
      info_out 'warning', warning


module.exports.note = (note) ->
  for name in ['css', 'html', 'js']
    if note[name]
      for msg in note[name] or []
        console.log '[' + name + ']', msg
