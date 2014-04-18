
esc   = String.fromCharCode 27
first = true


output = ->
  if first
    #             14,5    22,6     31,12          46,5    54,8       65,12          80,12          95,12          110,6
    process.stdout.write """

                ┌───────────────────────────────┬─────────────────────────────────┬──────────────┬──────────────┬────────┐
                │ Sources                       │ Compilable                      │ Concatenate  │ Minification │        │
                │ Files │ Loaded │ Size (bytes) │ Files │ Compiled │ Size (bytes) │ Size (bytes) │ Size (bytes) │ Deploy │
    ┌───────────┼───────┼────────┼──────────────┼───────┼──────────┼──────────────┼──────────────┼──────────────┼────────┤
    │ COFFE/JS  │       │        │              │       │          │              │              │              │        │
    │ SASS/CSS  │       │        │              │       │          │              │              │              │        │
    │ JADE/HTML │       │        │              │       │          │              ├──────────────┴──────────────┤        │
    └───────────┴───────┴────────┴──────────────┴───────┴──────────┴──────────────┘                             └────────┘

    """
    first = false

  n_grouped = (n) ->
    _n = String(n).split('').reverse()
    n = ''
    for char, i in _n
      n = ',' + n if i % 3 is 0 and i
      n = char + n
    n

  write = (x, len, msg, err) ->
    msg = n_grouped(msg) if msg and typeof msg is 'number'
    msg = msg or ''

    if err
      err = n_grouped(err) if typeof err is 'number'
      msg += '+' if msg
      msg += esc + '[0;31m' + err + esc + '[0m'
      len += 11

    if len > msg.length
      msg = (' ' for i in [0 ... len - msg.length]).join('') + msg
    else
      msg = msg.substr msg.length - len
    process.stdout.write '\r' + esc + '[' + x + 'C' + msg

  process.stdout.write esc + '[4A'
  repos =
    js:   require './js_repo'
    css:  require './css_repo'
    html: require './html_repo'
  for name, repo of repos
    write 14, 5, repo.pathes.length
    write 22, 6, repo.loaded
    write 31, 12, repo.size

    write 46, 5, repo.compilable
    write 54, 8, repo.compiled, repo.compileError
    write 65, 12, repo.compiledSize

    write 46, 5, repo.compilable
    write 54, 8, repo.compiled, repo.compileError
    write 65, 12, repo.compiledSize

    if repo.concatenator?.error
      write 80, 12, '', 'error'
    else if repo.concatenator?.src
      write 80, 12, repo.concatenator.src.length

    if repo.minifier?.error
      write 95, 12, '', 'error'
    else if repo.minifier?.src
      write 95, 12, repo.minifier.src.length

    process.stdout.write '\r' + esc + '[1B'
  process.stdout.write '\r' + esc + '[1B'


module.exports = output
