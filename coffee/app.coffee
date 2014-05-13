#!/usr/bin/env coffee

child_process = require 'child_process'

config = require './config'
stats  = require './stats'


unless config.output in ['fancy', 'plain']
  config.output = 'plain'
output = require './output/plugin/' + config.output


repo_count = 0

for name in ['js', 'css', 'html']
  do (name) ->
    path = __dirname + '/repo/' + name +
           (if __dirname.indexOf('/coffee/') then '.coffee' else '.js')
    repo = child_process.fork path, {cwd: process.cwd(), silent: true}
    repo_count += 1

    repo.stdout.on 'data', (data) ->
      process.stdout.write data

    repo.stderr.on 'data', (data) ->
      process.stderr.write data

    repo.on 'exit', (code, signal) ->
      repo_count -= 1
      unless repo_count
        console.log 'bye'
        process.exit 0

    repo.on 'message', (msg) ->
      switch msg?.type
        when 'stat'
          stats[msg.repo] ?= {}
          stats[msg.repo][msg.task] = msg.stat
          output.update msg
        when 'note'
          output.note msg
