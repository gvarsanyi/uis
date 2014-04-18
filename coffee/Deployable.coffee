Dependencies = require './Dependencies'
config       = require './config'
output       = require './output'


class Deployable
  constructor: ->
    @pathes  = []
    @sources = {}

    @update()

    @dirs = config.repos?[@constructor.name.replace('Repo', '').toLowerCase()] or
            (ext for ext of @extensions)
    @dirs = [@dirs] unless typeof @dirs is 'object'

    @watch()

  deploy: =>
    output() if @pathes.length

  minificationDone: =>
    output()
    @deploy()

  concatDone: =>
    output()
    if @minifier
      @minifier.minify @minificationDone
    else
      @deploy()

  compileDone: =>
    if @concatenator
      @concatenator.concat @concatDone
    else if @minifier
      @minifier.minify @minificationDone
    else
      @deploy()

  update: (path) =>
    @compilable   = 0
    @compiled     = 0
    @compileError = 0
    @compiledSize = 0
    @loaded       = 0
    @size         = 0
    for x, source of @sources
      @loaded += 1 if source.loaded
      @size   += source.src?.length or 0

      if source.compiler
        @compilable += 1
        if source.compiler.error?
          @compileError += 1
        else if source.compiler.src?
          @compiled += 1
          @compiledSize += source.compiler.src.length

    output() if @pathes.length

    # TODO: make it dependent on (allDirsLoaded and allCompiled) instead of
    # (hadSomethingToCompile and allCompiled)
    if @compilable and @compiled + @compileError is @compilable
      @compileDone()

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

      @update()
      watch_dir()

    updated = (event, file) =>
      if inst = instanciate_file file
        console.log 'event', event, file
        @sources[file] = inst
        @update()

    dir_pool = (dir for dir in @dirs)
    watch_dir = =>
      return unless dir_pool.length

      dir = dir_pool.shift()

      Dependencies::gaze() dir, (err, watcher) ->
        return console.error('watching failed: ' + dir) if err

        @on 'all', updated

        @watched watched

    watch_dir()


module.exports = Deployable
