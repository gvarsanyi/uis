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

boxlines =
  h: '─'
  v: '│'
  x: '┼'

print = (status, repo, task, msg...) ->
  icon   = ' ' + (icons[status] or ' ')
  output = if status is 'error' then 'error' else 'log'

  repo = ' [' + repo + ']'
  while repo.length < 7
    repo = ' ' + repo

  console[output] timestamp() + repo + icon + ' ' + task, msg...

obj_to_str = (status, inf) ->
  table = (table, push=0) ->
    align =
      left: (str, size, chr=' ') ->
        str = String str
        while str.length < size
          str += chr
        str
      right: (str, size, chr=' ') ->
        str = String str
        while str.length < size
          str = chr + str
        str

    msg = '\n'
    unless push
      push = ''
    else
      push = align.left '', push

    has_title = false
    for col, i in table.columns
      col.width = 0
      col.align = 'left' if col.align isnt 'right'
      if col.title?
        col.width = String(col.title).length
        has_title = true
      for row in table.data
        txt = if col.src? then row[col.src] else row[i]
        col.width = Math.max col.width, String(txt).length

    if has_title
      for col, i in table.columns
        msg += if i then ' ' + boxlines.v + ' ' else push + ' '
        msg += align[col.align] (col.title or ''), col.width
      msg += '\n'
      for col, i in table.columns
        msg += if i then boxlines.h + boxlines.x + boxlines.h else push + boxlines.h
        msg += align.left '', col.width, boxlines.h
      msg += boxlines.h + ' \n'

    for row, row_n in table.data
      for col, i in table.columns
        msg += if i then ' ' + boxlines.v + ' ' else push + ' '
        txt = if col.src? then row[col.src] else row[i]
        msg += align[col.align] txt, col.width
      msg += '\n'
    msg

  unless inf.file
    '[' + status.toUpperCase() + '] ' + String(inf) + '\n'

  out = '[' + status.toUpperCase() + '] ' + (inf.file or '') +
        (if inf.line then ' @ line ' + inf.line else '') + '\n'

  indent = '  '

  if inf.lines
    for n in [inf.lines.from .. inf.lines.to]
      if inf.lines[n]?
        push = if String(n).length < String(inf.lines.to).length then ' ' else ''
        pre = indent
        if n is inf.line or (typeof inf.line is 'object' and n in inf.line)
          pre = pre.split(' ').join('>')
        out += pre + '(' + n + ') ' + inf.lines[n] + '\n'

  if inf.title
    out += indent + inf.title + '\n'

  if inf.description
    out += indent + '  ' + subitem + ' ' +
           inf.description.split('\n').join('\n    ' + indent) + '\n'

  out += table(inf.table, 4) if inf.table?

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
  {done, count, error, warning, size, status} = update.stat

  error_state = 'start'
  error_state = 'check'   if done
  error_state = 'warning' if warning
  error_state = 'error'   if error


  if done or error or warning #or true
    msg = ''
    if error?
      msg = ': ' + ngroup error.length, 'error'
    if warning?
      msg += if msg then ', ' else ': '
      msg += ngroup warning.length, 'warning'
    if update.task is 'tester' and size
      msg += if msg then ' of ' else ': '
      msg += ngroup size, 'test'
    else if size and typeof size is 'number'
      msg += if msg then ', ' else ': '
      msg += ngroup size, 'byte'
    if update.task.substr(0, 5) is 'files' and status
      msg += if msg then ', ' else ': '
      msg += ngroup status, 'file'

#     msg += ' ::: ' + JSON.stringify update

    print error_state, update.repo, (types[update.task] or update.task) + msg

    if error?
      info_out 'error', error

    if warning?
      info_out 'warning', warning


module.exports.note = (note) ->
  console.log '[' + note.repo + ']', note.note
