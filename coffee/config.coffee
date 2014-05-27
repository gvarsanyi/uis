fs       = require 'fs'

minimist = require 'minimist'


argv = minimist process.argv[2 ..]


# -v or --version
if argv.v or argv.version
  pkg = require '../package.json'
  console.log pkg.name, 'v' + pkg.version
  process.exit 0


camelize = (str) ->
  str.replace /-([a-z])/g, (g) ->
    g[1].toUpperCase()

copy_opts = (from, to, from_str) ->
  for k, v of from
    k = camelize k
    if v and typeof v is 'object' and to[k] and typeof to[k] is 'object'
      copy_opts v, to[k], from_str
    else if from_str
      try
        to[k] = JSON.parse v
      catch
        to[k] = v
    else
      to[k] = v

load = (env='') ->
  env = '.' + env if env
  for dir in [cwd + '/.uis', cwd]
    break if opts
    for ext in ['coffee', 'js', 'json']
      try
        opts = require dir + '/uis' + env + '.conf.' + ext
        break
  unless opts
    console.error 'Missing ./[.uis/]uis' + env + '.conf.[coffee|js|json] file'
    process.exit 1

  copy_opts opts, options


options = module.exports

cwd = process.cwd()

load()


for env in argv._ or []
  load env

delete argv._
copy_opts argv, options, true
