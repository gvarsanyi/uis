gaze = require 'gaze'

config    = require './config'
messenger = require './messenger'


class Repo
  constructor: ->
    @pathes  = []
    @sources = {}

    @dirs = config.repo?[@constructor.name.replace('Repo', '').toLowerCase()]
    @dirs = [@dirs] unless typeof @dirs is 'object'

    @watch()

  stats: =>
    inf = {}
    for type, worker of @tasks
      inf[type] ?= {}
      for stat in ['count', 'error', 'warning', 'size', 'status']
        inf[type][stat] = val if val = worker[stat]()
    inf

  work: (callback) =>
    round = (err) ->
      if tasks.length
        unit = tasks.shift()
        unit.task.work ->
          if err = unit.task.error()
            messenger.sendStats()
            return callback?()
          messenger.sendStats()
          round()
      else
        callback?()

    tasks = ({name, task} for name, task of @tasks)
    round()
    return

  watch: =>
    instanciate_file = (file, basedir) =>
      ext = file.substr file.lastIndexOf('.') + 1
      if class_ref = @extensions[ext]
        return new class_ref @, file, basedir

    update = (event, file) =>
      @fileUpdate event, file

    watched = (err, tree) =>
      basedir = null
      return console.error(err) if err

      add_nodes = (tree) =>
        for path, node of tree
          basedir ?= if typeof node is 'string' then path else node[0]
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

      gaze dir, mode: 'watch', (err, watcher) ->
        return console.error('watching failed: ' + dir) if err

        @on 'all', update

        @watched watched

    watch_dir()


module.exports = Repo
