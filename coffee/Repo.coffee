Dependencies = require './Dependencies'
config       = require './config'
messenger    = require './messenger'


class Repo
  constructor: ->
    @pathes  = []
    @sources = {}

    @dirs = config.repo?[@constructor.name.replace('Repo', '').toLowerCase()]
    @dirs = [@dirs] unless typeof @dirs is 'object'

    @watch()

  deploy: =>
    @deployed = true
    messenger.sendStats()

  minificationDone: =>
    messenger.sendStats()
    @deploy()

  concatDone: =>
    messenger.sendStats()
    if @minifier
      @minifier.minify @minificationDone
    else
      @deploy()

  loadDone: =>
    messenger.sendStats()
    if @concatenator
      @concatenator.concat @concatDone
    else if @minifier
      @minifier.minify @minificationDone
    else
      @deploy()

  stats: =>
    inf = source: file: 0

    for x, source of @sources
      inf.source.file += 1

      if source.src?
        inf.source.load ?= 0
        inf.source.load += 1
        inf.source.size ?= 0
        inf.source.size += source.src.length
      if source.error?
        inf.source.error ?= 0
        inf.source.error += 1

      if source.compiler?
        inf.compile ?= {}
        inf.compile.file ?= 0
        inf.compile.file += 1

        if source.compiler.src?
          inf.compile.done ?= 0
          inf.compile.done += 1
          inf.compile.size ?= 0
          inf.compile.size += source.compiler.src.length
        if source.compiler.error?
          inf.compile.error ?= 0
          inf.compile.error += 1

    if @concatenator?
      inf.concat ?= {}

      if @concatenator.src?
        inf.concat.size ?= 0
        inf.concat.size += @concatenator.src.length
      if @concatenator.error?
        inf.concat.error ?= 0
        inf.concat.error += 1

    if @minifier?
      inf.minify ?= {}

      if @minifier.src?
        inf.minify.size ?= 0
        inf.minify.size += @minifier.src.length
      if @minifier.error?
        inf.minify.error ?= 0
        inf.minify.error += 1

    inf

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
