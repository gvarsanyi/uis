fs   = require 'fs'
path = require 'path'

gaze = require 'gaze'
md5  = require 'MD5'

messenger = require './messenger'


class WatchedFile
  constructor: (@compiler, @path) ->
    fs.readFile @path, encode: 'utf8', (err, data='') =>
      @hash = md5 data

  changed: (callback) =>
    fs.readFile @path, encode: 'utf8', (err, data='') =>
      if @hash isnt hash = md5 data
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
    if typeof source is 'function'
      callback = source
      source = undefined

    try
      for k of @_watched
        delete @_watched[k]
      @_gaze.close() if @_gaze
      delete @_watching
      for watchable in watchables
        @_watched[watchable] = new WatchedFile @, watchable

      updated = (event, file) =>
        @watchedFileChanged event, file, source

      gaze_error = null
      if watchables.length
        @_gaze = new gaze
        @_gaze.on 'all', updated
        @_gaze.on 'error', (err) ->
          gaze_error = err
        @_gaze.on 'ready', ->
          callback? gaze_error
        @_gaze.add watchables

        @_watching = true
      else
        delete @_gaze
        callback?()
    catch err
      callback? err

  watchedFileChanged: (event, file, source) =>
    if source and @source.sources[source.path]
      messenger.note 'changed: ' + @source.shortFile(source.path) +
                     ' (' + @source.shortFile(file) + ')'
      @workFile source, =>
        @followUp?(source) unless @error()
        @source.checkAllTasksFinished()
    else
      messenger.note 'changed: ' + @source.shortFile file
      @work()

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
    description: String(inf).split(path.resolve(process.cwd()) + '/').join('').trim()

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
