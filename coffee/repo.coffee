path = require 'path'

gaze = require 'gaze'

FilesLoader = require './task/files-loader'
config      = require './config'
messenger   = require './messenger'


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

    @tasks = filesLoader: new FilesLoader @
    for name, task of @getTasks?() or {}
      @tasks[name] = task

    @projectPath = path.resolve process.cwd()

    @watch()

  fileUpdate: (event, file, force_reload) =>
    # TODO fix per file wevents
#     short_file = =>
#       if file.substr(0, @projectPath.length) is @projectPath
#         return file.substr @projectPath.length + 1
#       file
#
#     if node = @sources[file] # changed/deleted
#       file = @name + ':' + file
#       node.tasks.filesLoader.work (err, changed) =>
#         if changed or force_reload
#           unless node.tasks.filesLoader.result()
#             messenger.note 'emptied: ' + short_file file
#           else
#             messenger.note 'updating: ' + short_file file
#             @work node
#     else # new file
#       messenger.note 'deleted: ' + short_file file

  work: (callback) =>
    @tasks.filesLoader.work()
#   work: (node, callback) =>
#     if typeof node is 'function'
#       callback = node
#       node = undefined
#
#     for name, task of @tasks when name isnt 'filesLoader' or not node
#       # TODO per-file todo
# #       if node and task.constructor.name is 'Multi'
# #         node.tasks[name].work()
# #       else
# #         task.work()
#       task.work()

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

        unless config[@name].test?.files
          delete config[@name].test
        else unless typeof config[@name].test.files is 'object'
          config[@name].test.files = [config[@name].test.files]

        watch = new gaze
        watch.on 'ready', (watcher) ->
          watched watcher.watched(), options
        watch.on 'all', update
        watch.add dir.repo

    watch_dir()

module.exports = Repo
