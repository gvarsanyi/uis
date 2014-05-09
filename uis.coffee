child_process = require 'child_process'

config = require './coffee/config'


unless config.output in ['fancy', 'plain']
  config.output = 'plain'
output = require './coffee/output/plugin/' + config.output


stats = {}

for name in ['js', 'css', 'html']
  do (name) ->
    path = __dirname + '/coffee/repo/' + name + '.coffee'
    repo = child_process.fork path, {cwd: process.cwd(), silent: true}

    repo.stdout.on 'data', (data) ->
      process.stdout.write data

    repo.stderr.on 'data', (data) ->
      process.stderr.write data

    repo.on 'message', (msg) ->
      if msg?.stats
        stats[k] = v for k, v of msg.stats
        output stats
