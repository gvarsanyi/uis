#!/usr/bin/env coffee

child_process = require 'child_process'

config = require './config'
stats  = require './stats'


unless config.output in ['fancy', 'plain']
  config.output = 'plain'
output = require './output/plugin/' + config.output


done       = false
ext        = if __dirname.split('/').pop() is 'coffee' then '.coffee' else '.js'
repo_count = 0
service    = null

wrap = (child, exit_callback) ->
  for iface in ['stderr', 'stdout']
    do (iface) ->
      child[iface].on 'data', (data) ->
        process[iface].write data
#   child.on 'error', (err) ->
#     console.error err
  child.on 'exit', exit_callback


stats.init {}, {}

if config.service
  service = child_process.fork __dirname + '/service' + ext,
    cwd:    process.cwd()
    silent: true

  wrap service, (code, signal) ->
    console.log 'service exited', code, signal

  service.on 'message', (msg) ->
    switch msg?.type
      when 'note'
        output.note msg

  service.send
    type: 'stat-init'
    data: stats.data
    ids:  stats.ids

for name in ['js', 'css', 'html', 'test']
  do (name) ->
    if config[name] and (name isnt 'test' or config.js)
      repo = child_process.fork __dirname + '/repo/' + name + ext,
        cwd:    process.cwd()
        silent: true
      repo_count += 1

      wrap repo, (code, signal) ->
        repo_count -= 1
        unless repo_count and not config.service
          console.log 'bye'
          process.exit 0

      repo.on 'message', (msg) ->
        msgs = stats.incoming msg
        if service
          for msg in msgs
            service.send msg
            switch msg?.type
              when 'stat'
                stats[msg.repo] ?= {}
                stats[msg.repo][msg.task] = msg.stat
                output.update msg
              when 'note'
                output.note msg

done = true
