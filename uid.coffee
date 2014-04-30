child_process = require 'child_process'

config = require './coffee/config'
output = require './coffee/output'


stats = {}


for name in ['js', 'css', 'html']
  do (name) ->
    polled  = 0
    replied = 0

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
      if replied < polled
        replied += 1
        setTimeout poll, 100

    poll = ->
      polled += 1
      repo.send 'stats'
    poll()
