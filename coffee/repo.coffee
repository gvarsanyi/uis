Dependencies = require './dependencies'
config       = require './config'
messenger    = require './messenger'
RepoStats    = require './repo-stats'


class Repo extends RepoStats
  constructor: ->
    @pathes  = []
    @sources = {}

    @dirs = config.repo?[@constructor.name.replace('Repo', '').toLowerCase()]
    @dirs = [@dirs] unless typeof @dirs is 'object'

    @watch()

  deployDone: =>
    messenger.sendStats()

  minificationDone: =>
    messenger.sendStats()
    if @deployer
      @deployer.deploy @deployDone
    else
      @deployDone()

  concatDone: =>
    messenger.sendStats()
    if @minifier
      @minifier.minify @minificationDone
    else if @deployer
      @deployer.deploy @deployDone
    else
      @deployDone()

  loadDone: =>
    messenger.sendStats()
    if @concatenator
      @concatenator.concat @concatDone
    else if @minifier
      @minifier.minify @minificationDone
    else if @deployer
      @deployer.deploy @deployDone
    else
      @deployDone()

  check: =>
    if @watchingAll
      stats = @stats()
      messenger.sendStats()
      if stats.compile and @constructor.name isnt 'JsRepo'
        if (stats.compile?.done or 0) + (stats.compile?.error or 0) is stats.compile?.file
          @loadDone()
      else
        if (stats.source?.load or 0) + (stats.source?.error or 0) is stats.source?.file
          @loadDone()

  watch: =>
    instanciate_file = (file) =>
      ext = file.substr file.lastIndexOf('.') + 1
      if class_ref = @extensions[ext]
        return new class_ref @, file

    watched = (err, tree) =>
      return console.error(err) if err

      add_nodes = (tree) =>
        for path, node of tree
          if typeof node is 'object'
            add_nodes node
          else if '/' isnt node.substr node.length - 1
            if not @sources[node] and inst = instanciate_file node
              @sources[node] = inst
              @pathes.push node

        null
      add_nodes tree

      watch_dir()

    updated = (event, file) =>
      if inst = instanciate_file file
        console.log 'event', event, file
        @sources[file] = inst

    dir_pool = (dir for dir in @dirs)
    watch_dir = =>
      unless dir_pool.length
        @watchingAll = true
        return

      dir = dir_pool.shift()

      Dependencies::gaze() dir, (err, watcher) ->
        return console.error('watching failed: ' + dir) if err

        @on 'all', updated

        @watched watched

    watch_dir()


module.exports = Repo
