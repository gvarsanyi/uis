#!/usr/bin/env coffee

child_process = require 'child_process'

config = require './config'


unless config.output in ['fancy', 'plain']
  config.output = 'plain'
output = require './output/plugin/' + config.output


stats = {}

for name in ['js', 'css', 'html']
  do (name) ->
    path = __dirname + '/repo/' + name +
           (if __dirname.indexOf('/coffee/') then '.coffee' else '.js')
    repo = child_process.fork path, {cwd: process.cwd(), silent: true}

    repo.stdout.on 'data', (data) ->
      process.stdout.write data

    repo.stderr.on 'data', (data) ->
      process.stderr.write data

    repo.on 'message', (msg) ->
      if msg?.stats
        output.stats msg.stats
      if msg?.state
        output.state msg.state
      if msg?.note
        output.note msg.note
