path = require 'path'

gaze   = require 'gaze'
glob   = require 'glob'
md5    = require 'MD5'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'

FilesLoader = require './task/files-loader'
config      = require './config'
messenger   = require './messenger'


class Repo
  constructor: ->
    @pathes  = []
    @sources = {}

    @name = @constructor.name.replace('Repo', '').toLowerCase()

    @projectPath = path.resolve process.cwd()
    @setTmp()

    unless config[@name].repos
      console.error 'Missing repos section in config'
      process.exit 1
    unless config[@name].repos instanceof Array
      config[@name].repos = [config[@name].repos]
    for item, i in config[@name].repos
      unless typeof item is 'object'
        config[@name].repos[i] = repo: item

    @tasks = filesLoader: new FilesLoader @
    for name, task of @getTasks?() or {}
      @tasks[name] = task

    @load()

  checkAllTasksFinished: =>
    if config.singleRun
      for name, task of @tasks
        return unless task.done()
      process.exit 0

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

  load: =>
    instanciate_file = (file, _options) =>
      ext = file.substr file.lastIndexOf('.') + 1
      if class_ref = @extensions[ext]
        options = {}
        for k, v of _options or {}
          options[k] = v
        return new class_ref @, file, options

    for repo in config[@name].repos or []
      options = {}
      for opt in ['testOnly', 'thirdParty'] when repo[opt]?
        options[opt] = repo[opt]
      for opt in ['basedir', 'deploy']
        if repo[opt]
          options[opt] = path.resolve repo[opt]
        else if config[@name][opt]
          options[opt] = path.resolve config[@name][opt]
      for opt in ['minify', 'rubysass']
        if repo[opt]
          options[opt] = repo[opt]
        else if config[@name][opt]
          options[opt] = config[@name][opt]

      repo.repo = [repo.repo] unless typeof repo.repo is 'object'

      for pattern in repo.repo
        pattern = @projectPath + '/' + pattern unless pattern[0] is '/'
        files = glob.sync pattern
        for file in files
          if @sources[file]
            for k, v of options
              @sources[file].options[k] = v
          else if not @sources[file] and inst = instanciate_file file, options
            @sources[file] = inst
            @pathes.push file

      unless config.singleRun
        watch = new gaze
        watch.on 'all', @fileUpdate
#         watch.on 'ready', (args...) => console.log @name, 'watch ready', args...
#         watch.on 'error', (args...) => console.log @name, 'watch error', args...
        watch.add repo.repo

    # start work
    setTimeout =>
      @tasks.filesLoader.work()

  shortFile: (file_path) =>
    if file_path.substr(0, @projectPath.length) is @projectPath
      return file_path.substr @projectPath.length + 1
    file_path

  setTmp: =>
#     tmp_dir = '/tmp'
#     for name in ['TMPDIR', 'TMP', 'TEMP']
#       tmp_dir = dir.replace /\/$/, '' if (dir = process.env[name])?
#     cwd = process.cwd()
#     @tmp     = tmp_dir + '/uis/' + path.basename(cwd) + '/' + md5(cwd) + '/'
    @tmp     = @projectPath + '/.uis/'
    @repoTmp = @tmp + @name + '/'
    try
      rimraf.sync @repoTmp
    catch err
      console.error '[ERROR] Could not clear' + @repoTmp
      process.exit 1
#     mkdirp @repoTmp

module.exports = Repo
