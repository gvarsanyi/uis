#!/usr/bin/env coffee

child_process = require 'child_process'

config        = require './config'
stats         = require './stats'


unless config.output in ['fancy', 'plain']
  config.output = 'plain'
output = require './output/plugin/' + config.output

stats.init {css: {}, html: {}, js: {}, test: {}}, {}

test_exit_code = 0


class Child
  ext = if __dirname.split('/').pop() is 'coffee' then '.coffee' else '.js'
  cwd = process.cwd()
  note_id = 0

  @count: 0
  @nodes: {}

  constructor: (@name, @onMsg) ->
    @path = name
    @path = 'repo/' + name unless name is 'service'

    @errBuffer = ''
    @outBuffer = ''

    @connect()

  connect: =>
    return if @node
    Child.nodes[@name] = @
    Child.count += 1

    @node = child_process.fork __dirname + '/' + @path + ext,
                               process.argv[2 ..],
                               {cwd, silent: true}

    @node.on 'error', (err) =>
      output.error({repo: 'uis', msg: @name + ' error', err}) if @node
      @del()

    @node.on 'close', (code, signal) =>
      output.log({repo: 'uis', msg: @name + ' closed', code, signal}) if @node
      @del()

    @node.on 'exit', (code, signal) =>
      output.log({repo: 'uis', msg: @name + ' exited', code, signal}) if @node
      @del()

    @node.on 'disconnect', =>
      if @node and not config.singleRun
        output.error {repo: 'uis', msg: @name + ' disconnected'}
      @del()

    @node.stderr.on 'data', (data) =>
      @errBuffer += data
      while (pos = @errBuffer.indexOf('\n')) > -1
        msg =
          repo: @name
          type: 'note'
          id:   note_id
          msg: @errBuffer.substr 0, pos + 1
        note_id += 1
        output.error msg
        if service and @name isnt 'service'
          service.send msg
        @errBuffer = @errBuffer.substr pos + 1

    @node.stdout.on 'data', (data) =>
      @outBuffer += data
      while (pos = @outBuffer.indexOf('\n')) > -1
        msg =
          repo: @name
          type: 'note'
          id:   note_id
          msg: @outBuffer.substr 0, pos + 1
        note_id += 1
        output.log msg
        if service and @name isnt 'service'
          service.send msg
        @outBuffer = @outBuffer.substr pos + 1

    if @onMsg?
      @node.on 'message', @onMsg

  del: =>
    return unless @node
    delete Child.nodes[@name]
    Child.count -= 1
    delete @node

    if Child.count is 1 and Child.nodes.service?.node?
      output.log {repo: 'uis', msg: 'Shutting down service'}
      Child.nodes.service.node.kill()
    if Child.count is 0 and Child.onAllDone?
      Child.onAllDone()

  send: (msg) =>
    return unless @node
    try
      @node.send msg
    catch err
      @del()
      return
    true

if config.service and not config.singleRun
  service = new Child 'service', (msg) ->
    if msg?.type is 'note'
      output.log msg
  service.send
    type: 'stat-init'
    data: stats.data
    ids:  stats.ids

for name in ['js', 'css', 'html', 'test'] when config[name]
  new Child name, (msg) ->
    if msg?.type is 'testExitCode'
      test_exit_code = msg.code
      return
    for msg in stats.incoming msg
      if service
        service.send msg
      switch msg?.type
        when 'stat'
          stats[msg.repo] ?= {}
          stats[msg.repo][msg.task] = msg.stat
          output.update msg
        when 'note'
          output.log msg

Child.onAllDone = ->
  if test_exit_code
    console.error '\ntest failed, boo'
    return process.exit 1

  console.log '\nbye! .oOo.'
