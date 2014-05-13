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
    @_count = 1
    callback?()

  count: (n) =>
    @_count = n if n?
    @_count

  done: =>
    (status = @status()) and status is @count()

  error: (add, source) =>
    if add?
      @_error ?= []
      @_error.push @wrapError add, source
    @_error

  warning: (add, source) =>
    if add?
      @_warning ?= []
      @_warning.push @wrapError add, source
    @_warning

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

  watch: (watchables=[], callback) =>
    try
      for k of @_watched
        delete @_watched[k]
      @_gaze.close() if @_gaze
      delete @_watching
      for watchable in watchables
        @_watched[watchable] = new WatchedFile @, watchable

      updated = @watchedFileChanged

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
    catch err
      callback? err

  watchedFileChanged: (event, file) =>
    @source.repo.fileUpdate 'changed', @source.path, true

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
      return @followUp? node

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

    work post_work

module.exports = Task
