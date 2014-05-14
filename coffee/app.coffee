#!/usr/bin/env coffee

child_process = require 'child_process'

config = require './config'
stats  = require './stats'


unless config.output in ['fancy', 'plain']
  config.output = 'plain'
output = require './output/plugin/' + config.output


ext        = if __dirname.indexOf('/coffee/') then '.coffee' else '.js'
repo_count = 0
service    = null

for name in ['js', 'css', 'html']
  do (name) ->
    repo = child_process.fork __dirname + '/repo/' + name + ext,
      cwd:    process.cwd()
      silent: true
    repo_count += 1

    repo.stdout.on 'data', (data) ->
      process.stdout.write data

    repo.stderr.on 'data', (data) ->
      process.stderr.write data

    repo.on 'exit', (code, signal) ->
      repo_count -= 1
      unless repo_count and not config.service
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

if config.service
  service = child_process.fork __dirname + '/service' + ext,
    cwd:    process.cwd()
    silent: true

  service.stdout.on 'data', (data) ->
    process.stdout.write data

  service.stderr.on 'data', (data) ->
    process.stderr.write data

  service.on 'exit', (code, signal) ->
    console.log 'service exited', code, signal

  service.on 'message', (msg) ->
    switch msg?.type
      when 'note'
        output.note msg
