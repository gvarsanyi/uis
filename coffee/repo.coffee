path = require 'path'

gaze = require 'gaze'
glob = require 'glob'

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

  checkAllTasksFinished: =>
    for name, task of @tasks
      return if not task.done() or not task.status()?
    unless config.singleRun
      messenger.note 'done'

  fileUpdate: (event, file, force_reload) =>
    if node = @sources[file] # changed/deleted
      @tasks.filesLoader.workFile node, (changed) =>
        if (changed or force_reload) and not @tasks.filesLoader.error()
          unless node.data
            messenger.note 'emptied: ' + @shortFile file
          else
            messenger.note 'updating: ' + @shortFile file
            @tasks.filesLoader.followUp? node
            @checkAllTasksFinished()
    else # new file
      messenger.note 'deleted: ' + @shortFile file

  shortFile: (file_path) =>
    if file_path.substr(0, @projectPath.length) is @projectPath
      return file_path.substr @projectPath.length + 1
    file_path

  work: (callback) =>
    @tasks.filesLoader.work()

  watch: =>
    instanciate_file = (file, options) =>
      ext = file.substr file.lastIndexOf('.') + 1
      if class_ref = @extensions[ext]
        return new class_ref @, file, options

    update = (event, file) =>
      @fileUpdate event, file

    upsert_file = (node, options) =>
      if @sources[node]
        for k, v of options
          @sources[node].options[k] = v
      else if not @sources[node] and inst = instanciate_file node, options
        @sources[node] = inst
        @pathes.push node

    watched = (tree, options) =>
      add_nodes = (tree) =>
        for full_path, node of tree
          if typeof node is 'object'
            add_nodes node
          else if '/' isnt node.substr node.length - 1
            upsert_file node, options

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

        if config.singleRun
          dir.repo = [dir.repo] unless typeof dir.repo is 'object'
          pattern_count = dir.repo.length
          pattern_done = 0
          for pattern in dir.repo
            unless pattern[0] is '/'
              pattern = process.cwd() + '/' + pattern
            glob pattern, (err, files) =>
              for file in files
                upsert_file file, options
              pattern_done += 1
              if pattern_count is pattern_done
                watch_dir()
        else
          watch = new gaze
          watch.on 'ready', (watcher) ->
            watched watcher.watched(), options
          watch.on 'all', update
          watch.add dir.repo

    watch_dir()

module.exports = Repo
