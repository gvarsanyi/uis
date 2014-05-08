path = require 'path'

gaze = require 'gaze'

Multi     = require './task/multi'
config    = require './config'
messenger = require './messenger'


class Repo
  minilog = (args...) ->
    msg = args.join ' '
    out = ''
    cols = process.stdout.columns or 120
    for char in msg
      unless (code = char.charCodeAt(0)) < 32 or code is 127
        out += char
    while out.length < cols
      out += ' '
    out = out.substr 0, cols
    process.stdout.write out + '\r'

  constructor: ->
    @pathes  = []
    @sources = {}

    @dirs = config.repo?[@constructor.name.replace('Repo', '').toLowerCase()]
    @dirs = [@dirs] unless typeof @dirs is 'object'

    @tasks = loader: new Multi @, 'loader'
    for name, task of @getTasks?() or {}
      @tasks[name] = task

    @watch()

  fileUpdate: (event, file, force_reload) =>
    if node = @sources[file] # changed/deleted
      repo_name = @constructor.name.replace('Repo', '').toLowerCase()
      file = repo_name + ':' + file
      node.tasks.loader.work (err, changed) =>
        if changed or force_reload
          unless node.tasks.loader.result()
            minilog 'deleted:', file
          else
            minilog 'updating:', file
            @work node, ->
              minilog 'updated:', file
    else # new file
      minilog 'deleted:', file

  stats: =>
    inf = {}
    for type, worker of @tasks
      inf[type] ?= {}
      for stat in ['count', 'error', 'warning', 'size', 'status', 'updatedAt']
        inf[type][stat] = val if val = worker[stat]()
    inf

  work: (node, callback) =>
    unless callback?
      callback = node
      node = undefined

    round = (err) ->
      if tasks.length
        unit = tasks.shift()
        if node and unit.task.constructor.name is 'Multi'
          task = node.tasks[unit.name]
        else
          task = unit.task
        task.work ->
          if err = task.error()
            messenger.sendStats()
            return callback? err
          messenger.sendStats()
          round()
      else
        callback?()

    tasks = for name, task of @tasks when name isnt 'loader' or not node
      if node and task.constructor.name is 'Multi'
        node.tasks[name].clear()
      else
        task.clear()
      {name, task}
    messenger.sendStats()
    round()
    return

  watch: =>
    instanciate_file = (file, basedir) =>
      ext = file.substr file.lastIndexOf('.') + 1
      if class_ref = @extensions[ext]
        return new class_ref @, file, basedir

    update = (event, file) =>
      @fileUpdate event, file

    watched = (tree, basedir) =>
      add_nodes = (tree) =>
        for full_path, node of tree
          if typeof node is 'object'
            add_nodes node
          else if '/' isnt node.substr node.length - 1
            if not @sources[node] and inst = instanciate_file node, basedir
              @sources[node] = inst
              @pathes.push node

        null
      add_nodes tree

      watch_dir()

    dir_pool = (dir for dir in @dirs)
    watch_dir = =>
      unless dir_pool.length
        @watchingAll = true
        return @work()

      dir = dir_pool.shift()
      do (dir) ->
        basedir = path.resolve dir

        watch = new gaze
        watch.on 'ready', (watcher) ->
          watched watcher.watched(), basedir
        watch.on 'all', update
        watch.add dir

    watch_dir()

module.exports = Repo
