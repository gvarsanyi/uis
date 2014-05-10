path = require 'path'

gaze = require 'gaze'

Multi     = require './task/multi'
config    = require './config'
messenger = require './messenger'


class Repo
  constructor: ->
    @pathes  = []
    @sources = {}

    @name = @constructor.name.replace('Repo', '').toLowerCase()

    @dirs = config[@name]?.repos
    unless @dirs instanceof Array
      @dirs = [@dirs]
    for item, i in @dirs
      unless typeof item is 'object'
        @dirs[i] = repo: item

    @tasks = loader: new Multi @, 'loader'
    for name, task of @getTasks?() or {}
      @tasks[name] = task

    @watch()

  fileUpdate: (event, file, force_reload) =>
    if node = @sources[file] # changed/deleted
      file = @name + ':' + file
      node.tasks.loader.work (err, changed) =>
        if changed or force_reload
          unless node.tasks.loader.result()
            messenger.note 'emptied: ' + file
          else
            messenger.note 'updating: ' + file
            @work node, ->
#               messenger.note 'updated: ' + file
    else # new file
      messenger.note 'deleted: ' + file

  stats: =>
    inf = {}
    for type, worker of @tasks
      inf[type] ?= {}
      for stat in ['count', 'error', 'warning', 'size', 'status', 'updatedAt',
                   'watched']
        inf[type][stat] = val if val = worker[stat]()
    inf

  work: (node, callback) =>
    unless callback?
      callback = node
      node = undefined

    round = (err) =>
      if tasks.length
        unit = tasks.shift()

        if config.output is 'fancy'
          messenger.sendStats()
        else
          messenger.sendState unit.name, 0

        if node and unit.task.constructor.name is 'Multi'
          task = node.tasks[unit.name]
        else
          task = unit.task
        task.work =>
          if err = task.error()
            if config.output is 'fancy'
              messenger.sendStats()
            else
              messenger.sendState unit.name, 1, err, task.warning()

            return setTimeout (callback or ->), 1

          if config.output is 'fancy'
            messenger.sendStats()
          else
            messenger.sendState unit.name, 1, null, task.warning(),
                                (item.name for item in tasks)

          setTimeout round, 1
      else
        if callback?
          setTimeout callback, 1

    tasks = for name, task of @tasks when name isnt 'loader' or not node
      if node and task.constructor.name is 'Multi'
        node.tasks[name].clear()
      else
        task.clear()
      {name, task}
    round()

  watch: =>
    instanciate_file = (file, options) =>
      ext = file.substr file.lastIndexOf('.') + 1
      if class_ref = @extensions[ext]
        return new class_ref @, file, options

    update = (event, file) =>
      @fileUpdate event, file

    watched = (tree, options) =>
      add_nodes = (tree) =>
        for full_path, node of tree
          if typeof node is 'object'
            add_nodes node
          else if '/' isnt node.substr node.length - 1
            if not @sources[node] and inst = instanciate_file node, options
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
      do (dir) =>
        options = {}
        for opt in ['testOnly', 'thirdParty'] when dir[opt]
          options[opt] = dir[opt]
        for opt in ['basedir', 'deploy', 'deployMinified']
          if dir[opt]
            options[opt] = path.resolve dir[opt]
          else if config[@name][opt]
            options[opt] = path.resolve config[@name][opt]
        for opt in ['rubysass']
          if dir[opt]
            options[opt] = dir[opt]
          else if config[@name][opt]
            options[opt] = config[@name][opt]

        watch = new gaze
        watch.on 'ready', (watcher) ->
          watched watcher.watched(), options
        watch.on 'all', update
        watch.add dir.repo

    watch_dir()

module.exports = Repo
