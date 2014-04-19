
esc   = String.fromCharCode 27
first = true

output = (stats) ->
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

  process.stdout.write esc + '[4A\r'
  for name, repo of {js: stats.js, css: stats.css, html: stats.html}
    if repo
      write 14, 5, repo.source.file
      write 22, 6, repo.source.load, repo.source.error
      write 31, 12, repo.source.size

      if repo.compile
        write 46, 5, repo.compile.file
        write 54, 8, repo.compile.done, repo.compile.error
        write 65, 12, repo.compile.size

      if repo.concat?.error
        write 80, 12, '', 'error'
      else if repo.concat?.size
        write 80, 12, repo.concat.size

      if repo.minify?.error
        write 95, 12, '', 'error'
      else if repo.minify?.size
        write 95, 12, repo.minify.size

    process.stdout.write '\r' + esc + '[1B'
  process.stdout.write '\r' + esc + '[1B'


module.exports = output
