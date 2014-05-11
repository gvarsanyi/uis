fs   = require 'fs'
path = require 'path'

gaze = require 'gaze'
md5  = require 'MD5'


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

  clear: (callback) ->
    delete @_error
    delete @_warning
    delete @_result
    delete @_status
    callback?()

  count: -> 1 # for compatibility with MultifileTask

  error: (add) =>
    if add?
      @_error ?= []
      @_error.push @wrapError add
    @_error

  warning: (add) =>
    if add?
      @_warning ?= []
      @_warning.push @wrapError add
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
      @_updatedAt = new Date().getTime()
    @_status

  updatedAt: =>
    @_updatedAt ?= new Date().getTime()

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

  work: (callback) =>  # should be overridden by all classes inherited from Task
    throw new Error 'Task.work() is not implemented for ' + @constructor.name

  wrapError: (inf) =>
    file:        @source?.shortPath?() or (@source?.name + ' repo')
    description: String(inf).split(path.resolve(process.cwd()) + '/').join('').trim()


module.exports = Task
