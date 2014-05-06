
esc   = String.fromCharCode 27
first = true
hourglass = '⌛'

output = (stats) ->
  if first
    process.stdout.write esc + '[48;5;236m    ╔═╗╔═╗╔═╗  ' + esc + '[0m\n'
    process.stdout.write '    ║  ╚═╗╚═╗\n'
    process.stdout.write '    ╚═╝╚═╝╚═╝\n\n'
    process.stdout.write esc + '[48;5;236m ╦ ╦╔╦╗╔╦╗╦    ' + esc + '[0m\n'
    process.stdout.write ' ╠═╣ ║ ║║║║\n'
    process.stdout.write ' ╩ ╩ ╩ ╩ ╩╩═╝\n\n'
    process.stdout.write esc + '[48;5;236m         ╦╔═╗  ' + esc + '[0m\n'
    process.stdout.write '         ║╚═╗\n'
    process.stdout.write '       ╚═╝╚═╝\n\n'
    process.stdout.write esc + '[48;5;236m ╔╦╗╔═╗╔═╗╔╦╗  ' + esc + '[0m\n'
    process.stdout.write '  ║ ╠╣ ╚═╗ ║\n'
    process.stdout.write '  ╩ ╚═╝╚═╝ ╩\n\n'

    first = false

  n_grouped = (n) ->
    _n = String(n).split('').reverse()
    n = ''
    for char, i in _n
      n = ',' + n if i % 3 is 0 and i
      n = char + n
    n

  print_block = (push, title, inf) ->
    process.stdout.write esc + '[' + push + 'C'

    title = (title + '                      ').substr 0, 18
    title = title + in_progress(inf) + ' '
    process.stdout.write esc + '[48;5;236m' + title + esc + '[0m' + esc +
                         '[1B' + esc + '[20D                    ' + esc + '[20D'

    has_n = ''
    if inf.status
      n = n_grouped(inf.status - (inf.warning?.length or 0) -
                    (inf.error?.length or 0))
      process.stdout.write esc + '[38;5;193m' + n + esc + '[0m'
      has_n = '+'
    if inf.warning?.length
      process.stdout.write has_n + esc + '[38;5;202m' +
                           n_grouped(inf.warning.length) + esc + '[0m'
      has_n = '+'
    if inf.error?.length
      process.stdout.write has_n + esc + '[38;5;202m' +
                           n_grouped(inf.error.length) + esc + '[0m'
      has_n = '+'
    if has_n
      process.stdout.write esc + '[38;5;246m files' + esc + '[0m'

    process.stdout.write '\n' + esc + '[' + push + 'C' +
                         '                    ' + esc + '[20D'
    if inf.size
      process.stdout.write esc + '[38;5;252m' + n_grouped(inf.size) + esc + '[0m'
      process.stdout.write esc + '[38;5;246m b' + esc + '[0m'

    process.stdout.write esc + '[2A\r'


  in_progress = (inf) ->
    if inf.status? and inf.status < inf.count then hourglass else ' '

  types =
    compiler:     'compile'
    concatenator: 'concat'
    deployer:     'deploy'
    loader:       'load'
    linter:       'lint'
    minifier:     'minify'

#   process.stdout.write(JSON.stringify stats.html) if stats.html
  process.stdout.write esc + '[16A\r'
  for name, repo of {css: stats.css, html: stats.html, js: stats.js, test: stats.test}
    if repo
      push = 15
      for type, inf of repo
        print_block push, types[type], inf
        push += 20

    process.stdout.write '\r' + esc + '[4B'


module.exports = output
