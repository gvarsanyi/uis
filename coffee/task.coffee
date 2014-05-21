fs   = require 'fs'
path = require 'path'

gaze = require 'gaze'
glob = require 'glob'
md5  = require 'MD5'

messenger = require './messenger'


class WatchedFile
  constructor: (@path) ->
    fs.readFile @path, encode: 'utf8', (err, data='') =>
      @data = data
      @hash = md5 data

  changed: (callback) =>
    fs.readFile @path, encode: 'utf8', (err, data='') =>
      if err
        return callback?()
      if @hash isnt hash = md5 data
        @data = data
        @hash = hash
        callback?()


class Task
  constructor: (@source) ->
    @_watched = {}

  clear: (callback) =>
    delete @_error
    delete @_warning
    delete @_result
    delete @_status
    delete @_startedAt
    delete @_finishedAt

    for file_path, source of @source.sources
      for underscored in ['_error', '_warning']
        if source[underscored]?
          delete source[underscored][@name]

    @_count = 1
    callback?()

  count: (n) =>
    @_count = n if n?
    @_count

  done: =>
    return true if (count = @count()) is 0
    return (status is count) if status = @status()
    false

  _issue: (type, add, source) =>
    underscored = '_' + type

    if add?
      if source
        source[underscored] ?= {}
        source[underscored][@name] ?= []
        source[underscored][@name].push @wrapError add, source
      else
        @[underscored] ?= []
        @[underscored].push @wrapError add

    list = (item for item in @[underscored] or [])
    for file_path, source of @source.sources
      if source[underscored]?[@name]?.length
        list.push(item) for item in source[underscored][@name] or []

    return null unless list.length
    list

  error: (add, source) =>
    @_issue 'error', add, source

  warning: (add, source) =>
    @_issue 'warning', add, source

  result: (value) =>
    @_result = value if value?
    @_result

  size: =>
    if typeof @_result is 'string'
      return @_result.length
    null

  status: (value) =>
    if value?
      @_status = value
      if value is 0
        @_startedAt = Date.now()
      else if value is @count()
        @_finishedAt = Date.now()
    @_status

  startedAt: =>
    @_startedAt

  finishedAt: =>
    @_finishedAt

  watch: (watchables=[], source, callback) =>
    watchables = [watchables] unless typeof watchables is 'object'
    if typeof source is 'function'
      callback = source
      source = undefined

    try
      unless source
        for k of @_watched
          delete @_watched[k]

        @_gaze.close() if @_gaze
        delete @_watching

      append = []
      for watchable in watchables
        watchable = @source.projectPath + '/' + watchable unless watchable[0] is '/'
        @_watched[watchable] = new WatchedFile watchable
        if watchable.indexOf('*') > -1
          for file in glob.sync watchable
            append.push file
            @_watched[file] = new WatchedFile file
      watchables = watchables.concat append

      updated = (event, file) =>
        if @_watched[file]
          @_watched[file].changed =>
            @watchedFileChanged event, file, source

      gaze_error = null
      count = 0
      total = watchables.length
      if watchables.length and watchables[0]
        @_gaze = new gaze
        @_gaze.on 'all', updated
        for watchable in watchables
          @_gaze.add watchable
#         @_gaze.on 'error', (err) ->
#           if gaze_error instanceof Array
#             gaze_error.push err
#           else if gaze_error
#             (gaze_error = [gaze_error]).push err
#           else
#             gaze_error = err
#         @_gaze.on 'ready', ->
#           count += total
#           if count is total
#             callback? gaze_error

        @_watching = true
      else unless source
        delete @_gaze
        callback?()
    catch err
      callback? err

  watchedFileChanged: (event, file, source) =>
    if source and @source.sources[source.path]
      console.log 'changed: ' + @source.shortFile(source.path) + ' (' +
                  @source.shortFile(file) + ')'
      @workFile source, =>
        @followUp?(source) unless @error()
        @source.checkAllTasksFinished()
      , true # forces stat update pre- and post-workFile
    else
      console.log 'changed: ' + @source.shortFile file
      @work {file}

  watched: =>
    i = null
    for k of @_watched or {}
      i ?= 0
      i += 1
    i

  work: =>  # should be overridden by all classes inherited from Task
    throw new Error 'Task.work() is not implemented for ' + @constructor.name

  wrapError: (inf, source) =>
    file:        source?.shortPath?() or (@source?.name + ' repo')
    title:       @name
    description: String(inf).split(path.resolve(@source.projectPath) + '/').join('').trim()

  preWork: (work_args, work) =>
    if typeof work_args[0] is 'object' and work_args[0].path
      node = work_args[0]
      callback = fn if typeof (fn = work_args[1]) is 'function'
    else
      callback = fn if typeof (fn = work_args[1]) is 'function'
    @clear()
    @status 0

    if @condition? and not @condition()
      @count 0
      messenger.sendStat @name
      @followUp?(node) unless @error()
      return @source.checkAllTasksFinished()

    messenger.sendStat @name

    post_work = (err, result, pass_back...) =>
      if err
        @error err
      if result
        @result result
      @status 1

      if pass_back?.length
        callback? @error, pass_back...
      else
        callback? @error

      messenger.sendStat @name

      @followUp?(node) unless @error()
      @source.checkAllTasksFinished()

    work post_work

module.exports = Task
